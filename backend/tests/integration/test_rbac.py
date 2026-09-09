"""Integration: admin role-based access control (Super Admin / Admin / Support)."""
import pytest

pytestmark = pytest.mark.integration


def test_team_list_requires_superadmin(client, admin_as):
    # Support and Admin are denied team management…
    admin_as("support")
    assert client.get("/api/admin/team").status_code == 403
    admin_as("admin")
    assert client.get("/api/admin/team").status_code == 403
    # …only the Super Admin may list the team.
    admin_as("superadmin")
    assert client.get("/api/admin/team").status_code == 200


def test_unauthenticated_admin_rejected(client):
    # No admin override + no token → 401/403 from the auth dependency.
    assert client.get("/api/admin/team").status_code in (401, 403)
