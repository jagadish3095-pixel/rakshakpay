"""Screenshots of the running apps for the documentary (Microsoft Edge via Playwright).

    python capture.py <app> <out_dir> <steps.json>

<app> is police | upi | bank. steps.json is a list of actions run in order:
    {"goto": "url"}            {"wait": seconds}
    {"click": [x, y]}          {"type": "text"}      {"key": "Enter"}
    {"shot": "name"}           {"storage": {"key": "json value", ...}}   (then reloads)
Coordinates are in CSS pixels of the viewport (police 1600x900, phones 412x892).
"""

import json
import pathlib
import sys

from playwright.sync_api import sync_playwright

VIEWPORTS = {
    "police": dict(viewport={"width": 1600, "height": 900}, device_scale_factor=1.2),
    "upi": dict(viewport={"width": 412, "height": 892}, device_scale_factor=2.5, is_mobile=True, has_touch=False),
    "bank": dict(viewport={"width": 412, "height": 892}, device_scale_factor=2.5, is_mobile=True, has_touch=False),
}


def main(app: str, out: str, steps_file: str) -> None:
    out_dir = pathlib.Path(out)
    out_dir.mkdir(parents=True, exist_ok=True)
    steps = json.loads(pathlib.Path(steps_file).read_text(encoding="utf-8"))
    profile = out_dir.parent / f"profile_{app}"
    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(
            str(profile), channel="msedge", headless=True, **VIEWPORTS[app],
            geolocation={"latitude": 12.9716, "longitude": 77.5946}, permissions=["geolocation"])
        page = ctx.pages[0] if ctx.pages else ctx.new_page()
        for s in steps:
            if "goto" in s:
                page.goto(s["goto"])
            elif "storage" in s:
                for k, v in s["storage"].items():
                    page.evaluate("([k, v]) => localStorage.setItem(k, v)", [k, v])
                page.reload()
            elif "deny_location" in s:
                ctx.clear_permissions()
            elif "allow_location" in s:
                ctx.grant_permissions(["geolocation"])
            elif "wait" in s:
                page.wait_for_timeout(int(s["wait"] * 1000))
            elif "click" in s:
                page.mouse.click(*s["click"])
                page.wait_for_timeout(700)
            elif "type" in s:
                page.keyboard.type(s["type"], delay=40)
            elif "key" in s:
                page.keyboard.press(s["key"])
            elif "shot" in s:
                page.screenshot(path=str(out_dir / f"{s['shot']}.png"))
                print("saved", s["shot"])
        ctx.close()


if __name__ == "__main__":
    main(*sys.argv[1:4])
