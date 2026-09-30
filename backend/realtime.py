"""Lightweight in-process WebSocket layer for live task/bid updates.

A single-process pub/sub: clients open ``/ws?token=<jwt>``; sync route handlers
push events via ``realtime.send_to_user`` / ``realtime.broadcast_role``. Messages
are tiny signals (e.g. ``{"type": "bid.new", "task_id": ...}``) — the app reacts
by refetching the relevant screen, so we never trust socket payloads as data.

Not horizontally scalable (no Redis fan-out) — fine for the current single
backend container. The apps also poll as a fallback, so a dropped socket only
delays updates, never loses them.
"""
from __future__ import annotations

import asyncio
from typing import Any, Callable, Dict, List

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect

from config import get_settings

router = APIRouter()
_settings = get_settings()


class _Conn:
    __slots__ = ("user_id", "role", "queue")

    def __init__(self, user_id: str, role: str, queue: "asyncio.Queue[dict]"):
        self.user_id = user_id
        self.role = role
        self.queue = queue


class RealtimeManager:
    def __init__(self) -> None:
        self._conns: List[_Conn] = []
        self._loop: asyncio.AbstractEventLoop | None = None

    def bind_loop(self, loop: asyncio.AbstractEventLoop) -> None:
        self._loop = loop

    def add(self, conn: _Conn) -> None:
        self._conns.append(conn)

    def remove(self, conn: _Conn) -> None:
        try:
            self._conns.remove(conn)
        except ValueError:
            pass

    def _deliver(self, predicate: Callable[[_Conn], bool], message: dict) -> None:
        for conn in list(self._conns):
            if predicate(conn):
                try:
                    conn.queue.put_nowait(message)
                except Exception:
                    pass

    def _schedule(self, predicate: Callable[[_Conn], bool], message: dict) -> None:
        loop = self._loop
        if loop is None:
            return
        try:
            loop.call_soon_threadsafe(self._deliver, predicate, message)
        except RuntimeError:
            pass

    # ---- public push API (safe to call from sync route handlers) ----
    def send_to_user(self, user_id: str, message: dict) -> None:
        if not user_id:
            return
        self._schedule(lambda c: c.user_id == user_id, message)

    def broadcast_role(self, role: str, message: dict) -> None:
        self._schedule(lambda c: c.role == role, message)


manager = RealtimeManager()


def _decode(token: str) -> dict | None:
    from jose import JWTError, jwt
    try:
        return jwt.decode(
            token, _settings["JWT_SECRET"], algorithms=[_settings["JWT_ALGORITHM"]]
        )
    except JWTError:
        return None


@router.websocket("/ws")
async def ws_endpoint(websocket: WebSocket, token: str = Query(default="")):
    payload = _decode(token)
    if payload is None or not payload.get("sub"):
        await websocket.close(code=1008)
        return

    user_id = str(payload["sub"])
    role = str(payload.get("role") or payload.get("user_type") or "customer")

    await websocket.accept()
    if manager._loop is None:
        manager.bind_loop(asyncio.get_running_loop())

    queue: "asyncio.Queue[dict]" = asyncio.Queue()
    conn = _Conn(user_id, role, queue)
    manager.add(conn)

    async def _sender() -> None:
        while True:
            msg = await queue.get()
            await websocket.send_json(msg)

    send_task = asyncio.create_task(_sender())
    try:
        # Greet, then block on receive so we notice client disconnects.
        await websocket.send_json({"type": "connected"})
        while True:
            await websocket.receive_text()  # ignore inbound (used as keepalive)
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        send_task.cancel()
        manager.remove(conn)


# Convenience helpers used by route handlers.
def notify_new_task() -> None:
    """A task just went live — nudge every connected tasker to refresh browse."""
    manager.broadcast_role("tasker", {"type": "task.new"})


def notify_new_bid(poster_id: str, task_id: str) -> None:
    manager.send_to_user(poster_id, {"type": "bid.new", "task_id": task_id})


def notify_applications_changed(user_id: str) -> None:
    manager.send_to_user(user_id, {"type": "applications.changed"})


def notify_alert(user_id: str, title: str, body: str, emoji: str,
                 notif_type: str, related_id: str | None) -> None:
    """Push a just-created in-app notification to the user's live socket so the
    app can show a transient heads-up banner (and deep-link on tap)."""
    manager.send_to_user(user_id, {
        "type": "alert",
        "alert": {
            "title": title,
            "body": body,
            "emoji": emoji or "",
            "notif_type": notif_type,
            "related_id": related_id or "",
        },
    })
