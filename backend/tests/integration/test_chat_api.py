"""Integration: chat message API enforces the contact-info guard."""
import pytest

pytestmark = pytest.mark.integration


def _conv(make_user, make_conversation):
    customer = make_user(role="customer")
    tasker = make_user(role="tasker")
    conv = make_conversation([customer.id, tasker.id])
    return customer, tasker, conv


def test_preset_message_allowed(client, auth_as, make_user, make_conversation):
    customer, tasker, conv = _conv(make_user, make_conversation)
    auth_as(customer.id, "customer")
    r = client.post(
        f"/api/chat/conversations/{conv.id}/messages",
        json={"text": "Sounds good, let's proceed."},
    )
    assert r.status_code == 201, r.text


def test_phone_number_blocked(client, auth_as, make_user, make_conversation):
    customer, tasker, conv = _conv(make_user, make_conversation)
    auth_as(customer.id, "customer")
    r = client.post(
        f"/api/chat/conversations/{conv.id}/messages",
        json={"text": "call me on 9876543210"},
    )
    assert r.status_code == 400


def test_location_share_allowed(client, auth_as, make_user, make_conversation):
    customer, tasker, conv = _conv(make_user, make_conversation)
    auth_as(customer.id, "customer")
    r = client.post(
        f"/api/chat/conversations/{conv.id}/messages",
        json={
            "text": "",
            "location": {
                "lat": 28.61,
                "lng": 77.20,
                "label": "Home",
                "address": "Green Park, New Delhi",
            },
        },
    )
    assert r.status_code == 201, r.text
    assert r.json()["location"]["label"] == "Home"


def test_non_participant_forbidden(client, auth_as, make_user, make_conversation):
    customer, tasker, conv = _conv(make_user, make_conversation)
    stranger = make_user(role="customer")
    auth_as(stranger.id, "customer")
    r = client.post(
        f"/api/chat/conversations/{conv.id}/messages",
        json={"text": "hello"},
    )
    assert r.status_code == 403
