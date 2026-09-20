#!/opt/homebrew/bin/python3

import math
import xml.etree.ElementTree as ET
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path


FAMILY = "SketchyBar Status 6"
OUTPUT = Path.home() / "Library/Fonts/SketchyBarStatus6.ttf"
ASSET_DIR = Path.home() / ".config/sketchybar/assets/status"


def draw_sf_symbol(filename, pen):
    paths = [node.attrib["d"] for node in ET.parse(ASSET_DIR / filename).iter() if node.tag.endswith("path")]

    bounds_pen = BoundsPen(None)
    for path in paths:
        parse_path(path, bounds_pen)
    x_min, y_min, x_max, y_max = bounds_pen.bounds

    scale = 760 / max(x_max - x_min, y_max - y_min)
    x_offset = 500 - (x_min + x_max) * scale / 2
    y_offset = 400 - (y_min + y_max) * scale / 2

    quadratic_pen = Cu2QuPen(pen, max_err=1.0, reverse_direction=False)
    transformed_pen = TransformPen(quadratic_pen, (scale, 0, 0, scale, x_offset, y_offset))
    for path in paths:
        parse_path(path, transformed_pen)


def sf_symbol_glyph(filename):
    pen = TTGlyphPen(None)
    draw_sf_symbol(filename, pen)
    return pen.glyph()


def rounded_rect(pen, x1, y1, x2, y2, radius, reverse=False):
    points = []
    for cx, cy, start in (
        (x2 - radius, y1 + radius, -90),
        (x2 - radius, y2 - radius, 0),
        (x1 + radius, y2 - radius, 90),
        (x1 + radius, y1 + radius, 180),
    ):
        for step in range(9):
            angle = math.radians(start + 90 * step / 8)
            points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    if reverse:
        points.reverse()
    pen.moveTo(points[0])
    for point in points[1:]:
        pen.lineTo(point)
    pen.closePath()


def battery_glyph(level):
    paths = [
        node.attrib["d"]
        for node in ET.parse(ASSET_DIR / "sf-battery-0-flat.svg").iter()
        if node.tag.endswith("path")
    ]
    bounds_pen = BoundsPen(None)
    for path in paths:
        parse_path(path, bounds_pen)
    x_min, y_min, x_max, y_max = bounds_pen.bounds
    scale = 760 / max(x_max - x_min, y_max - y_min)
    transform = (
        scale,
        0,
        0,
        scale,
        500 - (x_min + x_max) * scale / 2,
        400 - (y_min + y_max) * scale / 2,
    )

    pen = TTGlyphPen(None)
    transformed_pen = TransformPen(Cu2QuPen(pen, max_err=1.0), transform)

    body = RecordingPen()
    parse_path(paths[0], body)
    outer_contour = RecordingPen()
    for operation in body.value:
        outer_contour.value.append(operation)
        if operation[0] == "closePath":
            break
    outer_contour.replay(transformed_pen)
    parse_path(paths[1], transformed_pen)

    empty_width = round(553 * (100 - level) / 100)
    if empty_width:
        rounded_rect(pen, 737 - empty_width, 291, 737, 508, min(40, empty_width / 2), reverse=True)
    return pen.glyph()


def empty_glyph():
    return TTGlyphPen(None).glyph()


def main():
    glyphs = {
        ".notdef": empty_glyph(),
        "wifi": sf_symbol_glyph("sf-wifi.svg"),
        "controlCenter": sf_symbol_glyph("sf-switch-2.svg"),
    }
    character_map = {0xE020: "wifi", 0xE021: "controlCenter"}
    metrics = {".notdef": (1000, 0), "wifi": (1000, 0), "controlCenter": (1000, 0)}

    for index, level in enumerate(range(0, 101, 10)):
        name = f"battery{level}"
        charging_name = f"batteryCharging{level}"
        glyphs[name] = battery_glyph(level)
        glyphs[charging_name] = sf_symbol_glyph("sf-battery-charging-flat.svg")
        character_map[0xE000 + index] = name
        character_map[0xE010 + index] = charging_name
        metrics[name] = (850, 0)
        metrics[charging_name] = (1000, 0)

    glyph_order = list(glyphs)
    builder = FontBuilder(1000, isTTF=True)
    builder.setupGlyphOrder(glyph_order)
    builder.setupCharacterMap(character_map)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(metrics)
    builder.setupHorizontalHeader(ascent=800, descent=-200)
    builder.setupNameTable(
        {
            "familyName": FAMILY,
            "styleName": "Regular",
            "uniqueFontIdentifier": "SketchyBarStatus6-Regular",
            "fullName": f"{FAMILY} Regular",
            "psName": "SketchyBarStatus6-Regular",
            "version": "Version 6.0",
        }
    )
    builder.setupOS2(
        sTypoAscender=800,
        sTypoDescender=-200,
        usWinAscent=800,
        usWinDescent=200,
    )
    builder.setupPost()
    builder.setupMaxp()
    builder.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
