"""Phase 7: one-tap "Reset & load demo story" from the police console."""
from app.routers import demo
from app.routers.police import DEMO_OFFICER


def police_login(client):
    r = client.post("/api/police/login", json={"badge_id": DEMO_OFFICER["badge_id"], "password": DEMO_OFFICER["password"]})
    return {"Authorization": f"Bearer {r.json()['token']}"}


def test_load_story_needs_police_and_plays_the_whole_story(client, monkeypatch):
    monkeypatch.setattr(demo, "ADMIN_KEY", "cloud-secret")  # like the cloud server
    assert client.post("/api/demo/load-story").status_code == 403
    old = police_login(client)

    r = client.post("/api/demo/load-story", params={"file_complaint": True}, headers=old)
    assert r.status_code == 200, r.text
    story = r.json()
    assert len(story["people"]) == 9
    # the victim's copy has only the acknowledgement and status
    assert story["complaint"]["status"] == "UNDER_INVESTIGATION" and "held" not in story["complaint"]

    # the wipe removed the old login; the returned one works
    assert client.get("/api/police/dashboard", headers=old).status_code == 401
    fresh = {"Authorization": f"Bearer {story['police_token']}"}
    dash = client.get("/api/police/dashboard", headers=fresh).json()
    assert dash["complaints"] == 1 and dash["mule_accounts"] >= 7 and dash["held"] == 30_000_00

    # plain reset (no story) also works with a police login
    assert client.post("/api/demo/reset").status_code == 403
    plain = client.post("/api/demo/reset", headers=fresh)
    assert plain.status_code == 200
    fresh = {"Authorization": f"Bearer {plain.json()['police_token']}"}
    assert client.get("/api/police/dashboard", headers=fresh).json()["complaints"] == 0

    # loading again starts from scratch (no "already exists" errors)
    again = client.post("/api/demo/load-story", headers=fresh).json()
    assert again["complaint"] is None
    assert client.get("/api/police/dashboard", headers={"Authorization": f"Bearer {again['police_token']}"}).json()["complaints"] == 0
