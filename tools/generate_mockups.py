from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


WIDTH = 1080
HEIGHT = 1920
PHONE_MARGIN = 54
RADIUS = 42

WINDOW = "#efe8e4"
SURFACE = "#fbf7f3"
WHITE = "#ffffff"
TEXT = "#2f2a26"
MUTED = "#746b65"
LINE = "#e5d9cf"
YELLOW = "#f7d37a"
YELLOW_SOFT = "#fff1c7"
GREEN = "#7cbc7e"
GREEN_SOFT = "#e5f3d8"
BLUE = "#95bce0"
BLUE_SOFT = "#e4edf9"
CORAL_SOFT = "#fde2d8"
TEAL = "#59b6a9"
TEAL_SOFT = "#dbf3ef"
ACCENT = "#a8ca46"


def load_font(size: int, bold: bool = False):
    candidates = []
    if bold:
        candidates.extend(
            [
                r"C:\Windows\Fonts\segoeuib.ttf",
                r"C:\Windows\Fonts\arialbd.ttf",
            ]
        )
    candidates.extend(
        [
            r"C:\Windows\Fonts\segoeui.ttf",
            r"C:\Windows\Fonts\arial.ttf",
        ]
    )
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


FONT_H1 = load_font(60, bold=True)
FONT_H2 = load_font(42, bold=True)
FONT_H3 = load_font(30, bold=True)
FONT_BODY = load_font(25)
FONT_META = load_font(21)
FONT_BUTTON = load_font(24, bold=True)


def rounded(draw: ImageDraw.ImageDraw, box, fill, outline=LINE, width=2, radius=32):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def chip(draw, xy, text, fill):
    x, y = xy
    w = 24 + int(len(text) * 13.5)
    h = 48
    rounded(draw, (x, y, x + w, y + h), fill, radius=24)
    draw.text((x + 14, y + 11), text, fill=TEXT, font=FONT_META)
    return w


def button(draw, box, text, fill, fg=WHITE):
    rounded(draw, box, fill, outline=fill, radius=28)
    x1, y1, x2, y2 = box
    bbox = draw.textbbox((0, 0), text, font=FONT_BUTTON)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((x1 + (x2 - x1 - tw) / 2, y1 + (y2 - y1 - th) / 2 - 2), text, fill=fg, font=FONT_BUTTON)


def paragraph(draw, text, xy, font, fill, max_width, line_gap=10):
    words = text.split()
    x, y = xy
    lines = []
    current = ""
    for word in words:
        test = f"{current} {word}".strip()
        bbox = draw.textbbox((0, 0), test, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = test
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    for line in lines:
        draw.text((x, y), line, fill=fill, font=font)
        bbox = draw.textbbox((0, 0), line, font=font)
        y += (bbox[3] - bbox[1]) + line_gap
    return y


def phone_canvas():
    image = Image.new("RGB", (WIDTH, HEIGHT), WINDOW)
    draw = ImageDraw.Draw(image)
    rounded(draw, (PHONE_MARGIN, PHONE_MARGIN, WIDTH - PHONE_MARGIN, HEIGHT - PHONE_MARGIN), SURFACE, radius=64)
    return image, draw


def auth_mockup(out_path: Path):
    image, draw = phone_canvas()
    rounded(draw, (110, 120, 970, 540), WHITE, radius=46)
    draw.text((140, 165), "Sudarshan", fill=TEXT, font=FONT_H1)
    paragraph(
        draw,
        "Bihar Board study app ka mobile-first version. Fast login, soft cards, and clear daily study flow.",
        (140, 255),
        FONT_BODY,
        MUTED,
        770,
    )
    cx = 140
    for label, fill in [("Guest", YELLOW_SOFT), ("Email", BLUE_SOFT), ("Google", TEAL_SOFT), ("Trial Ready", CORAL_SOFT)]:
        cx += chip(draw, (cx, 400), label, fill) + 12

    rounded(draw, (110, 590, 970, 1500), WHITE, radius=46)
    draw.text((150, 645), "Authentication", fill=TEXT, font=FONT_H2)
    draw.text((150, 715), "Sign in to save progress and unlock shared tests", fill=MUTED, font=FONT_BODY)
    for idx, label in enumerate(["Name", "Email", "Password"]):
        top = 820 + (idx * 160)
        rounded(draw, (140, top, 940, top + 100), SURFACE, radius=28)
        draw.text((175, top + 31), label, fill=MUTED, font=FONT_BODY)
    button(draw, (140, 1330, 940, 1430), "Sign In With Email", ACCENT)
    button(draw, (140, 1455, 540, 1550), "Guest", YELLOW, fg=TEXT)
    button(draw, (560, 1455, 940, 1550), "Google", GREEN)
    image.save(out_path)


def dashboard_mockup(out_path: Path):
    image, draw = phone_canvas()
    rounded(draw, (110, 120, 970, 530), BLUE_SOFT, radius=46)
    draw.text((145, 160), "Study sharp,\nmove fast.", fill=TEXT, font=FONT_H1, spacing=0)
    paragraph(
        draw,
        "Warm mobile dashboard with daily test, streak, weak topic, and trial card all visible at a glance.",
        (145, 355),
        FONT_BODY,
        MUTED,
        740,
    )
    button(draw, (145, 445, 460, 525), "Open Tests", ACCENT)
    button(draw, (490, 445, 760, 525), "Admin", WHITE, fg=TEXT)

    cards = [
        ((110, 575, 525, 835), YELLOW_SOFT, "Daily Goal", "2 tests"),
        ((555, 575, 970, 835), GREEN_SOFT, "Streak", "5 days"),
        ((110, 865, 525, 1125), CORAL_SOFT, "Weak Topic", "Acids & Bases"),
        ((555, 865, 970, 1125), TEAL_SOFT, "Trial", "7 days left"),
    ]
    for box, fill, title, value in cards:
        rounded(draw, box, fill, radius=36)
        draw.text((box[0] + 28, box[1] + 34), title, fill=MUTED, font=FONT_META)
        draw.text((box[0] + 28, box[1] + 104), value, fill=TEXT, font=FONT_H2)

    rounded(draw, (110, 1160, 970, 1620), WHITE, radius=42)
    draw.text((145, 1200), "Today's Push", fill=TEXT, font=FONT_H2)
    paragraph(
        draw,
        "Daily Weak Topic Drill | Science | Chemical Reactions | 12 min timer",
        (145, 1280),
        FONT_BODY,
        MUTED,
        760,
    )
    button(draw, (145, 1480, 560, 1570), "Start Daily Test", ACCENT)
    image.save(out_path)


def tests_mockup(out_path: Path):
    image, draw = phone_canvas()
    draw.text((125, 135), "Published Tests", fill=TEXT, font=FONT_H1)
    y = 270
    cards = [
        (YELLOW_SOFT, "Daily Weak Topic Drill", "Science | Chemical Reactions", ["Daily", "Published", "Level 1"], "10 questions | 12 min"),
        (WHITE, "Board Sprint Set", "Math | Quadratic Equations", ["Published", "Level 2"], "15 questions | 20 min"),
        (WHITE, "Subjective Writing Push", "SST | Nationalism in India", ["Level 1"], "6 questions | 18 min"),
    ]
    for fill, title, subtitle, tags, meta in cards:
        rounded(draw, (110, y, 970, y + 360), fill, radius=40)
        tx = 145
        for tag in tags:
            tx += chip(draw, (tx, y + 35), tag, BLUE_SOFT if "Level" in tag else (TEAL_SOFT if tag == "Published" else YELLOW)) + 10
        draw.text((145, y + 115), title, fill=TEXT, font=FONT_H2)
        draw.text((145, y + 178), subtitle, fill=MUTED, font=FONT_BODY)
        draw.text((145, y + 240), meta, fill=TEXT, font=FONT_BODY)
        button(draw, (720, y + 225, 920, y + 305), "Start", ACCENT)
        y += 390
    image.save(out_path)


def results_mockup(out_path: Path):
    image, draw = phone_canvas()
    rounded(draw, (110, 120, 970, 520), GREEN_SOFT, radius=46)
    draw.text((145, 160), "Results", fill=TEXT, font=FONT_H1)
    draw.text((145, 275), "8 / 10 correct  |  80%", fill=TEXT, font=FONT_H2)
    draw.text((145, 350), "Time 09:42 / 12 min", fill=MUTED, font=FONT_BODY)
    draw.text((145, 405), "Strong attempt. Ab tougher set do.", fill=TEXT, font=FONT_BODY)

    rounded(draw, (110, 560, 970, 1030), WHITE, radius=42)
    draw.text((145, 600), "Weak Topics", fill=TEXT, font=FONT_H2)
    for idx, line in enumerate(["Indicators: 1 mistake", "Acids and Bases: 1 mistake"]):
        draw.text((155, 705 + idx * 70), line, fill=MUTED, font=FONT_BODY)

    rounded(draw, (110, 1070, 970, 1500), TEAL_SOFT, radius=42)
    draw.text((145, 1110), "Next Move", fill=TEXT, font=FONT_H2)
    paragraph(
        draw,
        "Sabse pehle Indicators revise karo, phir same chapter ka ek aur sprint do. Notebook cards auto-generate honge.",
        (145, 1200),
        FONT_BODY,
        TEXT,
        760,
    )
    button(draw, (145, 1385, 540, 1475), "Back To Home", ACCENT)
    image.save(out_path)


def main():
    out_dir = Path(__file__).resolve().parents[1] / "mockups"
    out_dir.mkdir(parents=True, exist_ok=True)

    auth_mockup(out_dir / "auth-screen.png")
    dashboard_mockup(out_dir / "dashboard-screen.png")
    tests_mockup(out_dir / "tests-screen.png")
    results_mockup(out_dir / "results-screen.png")
    print(out_dir)


if __name__ == "__main__":
    main()
