"""Render short, illustrative AeroSpace feature videos from vector frames.

Run: uv run --with cairosvg python docs/assets/render-demos.py
Requires ffmpeg on PATH. The videos show schematic windows, not a screen recording.
"""

from __future__ import annotations

import math
import subprocess
import tempfile
from pathlib import Path

import cairosvg


HERE = Path(__file__).resolve().parent
WIDTH, HEIGHT = 1200, 676
FPS = 20
FONT = "-apple-system, BlinkMacSystemFont, Helvetica, sans-serif"


def ease(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3 - 2 * value)


def ramp(time: float, start: float, end: float) -> float:
    return ease((time - start) / (end - start))


def mix(a: float, b: float, amount: float) -> float:
    return a + (b - a) * amount


def rect(x, y, w, h, fill, radius=0, opacity=1, stroke="none", stroke_width=0):
    return (
        f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" '
        f'rx="{radius}" fill="{fill}" opacity="{opacity:.3f}" '
        f'stroke="{stroke}" stroke-width="{stroke_width}"/>'
    )


def label(x, y, words, size=25, color="#e9edfb", weight=500, anchor="start", opacity=1):
    return (
        f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" '
        f'fill="{color}" font-weight="{weight}" text-anchor="{anchor}" '
        f'opacity="{opacity:.3f}">{words}</text>'
    )


def window(x, y, w, h, name, opacity=1, accent="#8598f1"):
    if opacity <= 0:
        return ""
    body = [f'<g opacity="{opacity:.3f}">']
    body.append(rect(x, y, w, h, "#f6f7fb", 10))
    body.append(rect(x, y, w, 35, "#dfe5f2", 9))
    body.append(rect(x, y + 26, w, 10, "#dfe5f2"))
    for cx, colour in [(x + 15, "#f17875"), (x + 30, "#f4c865"), (x + 45, "#69c786")]:
        body.append(f'<circle cx="{cx:.2f}" cy="{y + 17:.2f}" r="4" fill="{colour}"/>')
    body.append(label(x + w / 2, y + 22, name, 13, "#526179", 600, "middle"))
    if h > 100:
        body.append(rect(x + 17, y + 55, max(20, w * .44), 8, accent, 4, .8))
        body.append(rect(x + 17, y + 75, max(20, w - 40), 6, "#c7d0df", 3))
        body.append(rect(x + 17, y + 91, max(20, w - 63), 6, "#d3dbe8", 3))
        if h > 155:
            body.append(rect(x + 17, y + 119, max(20, w - 34), max(22, h - 153), "#e8edf6", 7))
    body.append("</g>")
    return "".join(body)


def frame(headline, subhead, scene, footer):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" '
        f'viewBox="0 0 {WIDTH} {HEIGHT}">'
        '<defs><linearGradient id="bg" x2="1" y2="1">'
        '<stop stop-color="#111a31"/><stop offset="1" stop-color="#101024"/>'
        '</linearGradient><linearGradient id="screen" x2="1" y2="1">'
        '<stop stop-color="#343d68"/><stop offset="1" stop-color="#1e2948"/>'
        '</linearGradient></defs>'
        + rect(0, 0, WIDTH, HEIGHT, "url(#bg)")
        + rect(42, 40, 11, 11, "#8e9fff", 3)
        + label(64, 52, "AEROSPACE", 17, "#aebbf1", 700)
        + label(42, 102, headline, 40, "#f1f3ff", 750)
        + label(43, 137, subhead, 21, "#aab5d2")
        + scene
        + rect(42, 605, 1116, 1, "#405075", opacity=.65)
        + label(43, 642, footer, 19, "#bac6e0")
        + '</svg>'
    )


def monitor(x, y, w, h, caption):
    return (
        rect(x - 8, y - 8, w + 16, h + 16, "#0a0e1c", 17, stroke="#526087", stroke_width=2)
        + rect(x, y, w, h, "url(#screen)", 9)
        + rect(x, y, w, 24, "#18203a", 8)
        + label(x + 14, y + 17, "AeroSpace", 10, "#bdc6e1", 650)
        + (label(x + w / 2, y + h + 41, caption, 16, "#a8b4d2", 600, "middle") if caption else "")
    )


def focus_svg(time):
    enter = ramp(time, 1.15, 2.25)
    leave = ramp(time, 4.65, 5.65)
    amount = enter * (1 - leave)
    shade = .72 * ramp(time, 1.35, 2.2) * (1 - ramp(time, 4.7, 5.6))
    xs = [83, 447, 811]
    y, w, h = 202, 306, 285
    parts = [monitor(x, y, w, h, name) for x, name in zip(xs, ["LEFT", "CENTRE", "RIGHT"])]
    parts += [window(98, 243, 133, 224, "Mail"), window(243, 243, 130, 224, "Tasks"),
              window(462, 243, 133, 224, "Browser"), window(607, 243, 130, 224, "Notes"),
              window(826, 243, 133, 224, "Chat")]
    for x in xs:
        parts.append(rect(x, y, w, h, "#060916", 9, shade))
    selected_x = mix(971, 513, amount)
    selected_y = mix(243, 229, amount)
    selected_w = mix(130, 174, amount)
    selected_h = mix(224, 243, amount)
    parts.append(window(selected_x, selected_y, selected_w, selected_h, "Writing", accent="#6d81d2"))
    key_opacity = ramp(time, .62, 1.0) * (1 - ramp(time, 2.3, 2.7))
    parts.append(rect(490, 531, 220, 48, "#788bee", 12, key_opacity))
    parts.append(label(600, 562, "Caps + Z", 24, "#ffffff", 700, "middle", key_opacity))
    focus_opacity = ramp(time, 2.0, 2.35) * (1 - ramp(time, 4.4, 4.7))
    parts.append(label(600, 562, "FOCUS MODE", 22, "#d9e0ff", 700, "middle", focus_opacity))
    exit_opacity = ramp(time, 4.35, 4.7) * (1 - ramp(time, 5.7, 6.0))
    parts.append(label(600, 562, "Caps + Z again · or click outside", 20, "#d9e0ff", 600, "middle", exit_opacity))
    return frame("Focus Mode", "Bring the active window to the centre display.", "".join(parts),
                 "Dim the rest of the desktop. Exit to restore the tiled layout.")


def lone_svg(time):
    shrink = ramp(time, 1.1, 2.35)
    second = ramp(time, 4.5, 5.4)
    reset = ramp(time, 6.1, 6.75)
    amount = shrink * (1 - reset)
    x, y, w, h = 238, 189, 724, 329
    parts = [monitor(x, y, w, h, "")]
    lone_x = mix(253, 427, amount)
    lone_w = mix(694, 347, amount)
    if second > 0:
        lone_x = mix(lone_x, 253, second * (1 - reset))
        lone_w = mix(lone_w, 341, second * (1 - reset))
    parts.append(window(lone_x, 226, lone_w, 275, "Writing", accent="#7187cf"))
    parts.append(window(606, 226, 341, 275, "Reference", second * (1 - reset), "#73b6a5"))
    measure_opacity = ramp(time, 2.0, 2.45) * (1 - ramp(time, 4.3, 4.75))
    parts.append(rect(427, 549, 347, 3, "#8799ed", 1, measure_opacity))
    parts.append(label(600, 581, "50% of usable width", 20, "#c8d3f8", 650, "middle", measure_opacity))
    initial_opacity = 1 - ramp(time, 1.15, 1.55)
    parts.append(label(600, 581, "One tiled window", 20, "#c8d3f8", 650, "middle", initial_opacity))
    tiled_opacity = ramp(time, 5.0, 5.4) * (1 - ramp(time, 6.0, 6.45))
    parts.append(label(600, 581, "Another window joins: normal tiling", 20, "#c8d3f8", 650, "middle", tiled_opacity))
    return frame("Single window width", "Give a lone tile comfortable space on a wide display.",
                 "".join(parts), "Rule shown: 2560-point monitor, centred window at 50% width.")


def render(name, duration, draw):
    output = HERE / f"{name}.mp4"
    with tempfile.TemporaryDirectory(prefix="aerospace-demo-") as temp:
        path = Path(temp)
        for index in range(math.ceil(duration * FPS)):
            time = index / FPS
            svg = draw(time)
            cairosvg.svg2png(bytestring=svg.encode(), write_to=str(path / f"{index:04d}.png"))
            if index == round(3 * FPS):
                (HERE / f"{name}-preview.svg").write_text(svg)
        subprocess.run([
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-framerate", str(FPS),
            "-i", str(path / "%04d.png"), "-c:v", "libx264", "-crf", "21", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart", str(output),
        ], check=True)
    print(output)


if __name__ == "__main__":
    render("focus-mode-demo", 6.6, focus_svg)
    render("single-window-width-demo", 7.1, lone_svg)
