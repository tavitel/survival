#!/usr/bin/env python3
"""Генерация стартовых ассетов для проекта (запускается один раз разработчиком).

Создаёт:
  assets/sprites/player.png      - атлас персонажа, 4 ряда (down/left/right/up) x 3 кадра, 16x20 на кадр
  assets/tiles/grass_atlas.png   - тайлсет 32x32: трава / камень / вода
  assets/tiles/missing_tile.png  - полностью прозрачная "отсутствующая" плитка
"""
import os
import random

from PIL import Image, ImageDraw

TILE = 32
PLAYER_W, PLAYER_H = 16, 20
FRAMES = 3
ROWS = ["down", "left", "right", "up"]


def gen_player(path: str) -> None:
    img = Image.new("RGBA", (PLAYER_W * FRAMES, PLAYER_H * len(ROWS)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    body = (52, 96, 168, 255)       # туловище (синяя рубаха)
    skin = (232, 184, 138, 255)     # лицо/руки
    hair = (70, 46, 28, 255)        # волосы
    leg = (40, 40, 56, 255)         # штаны
    boot = (20, 20, 24, 255)
    eye = (24, 24, 32, 255)

    for r, row in enumerate(ROWS):
        y0 = r * PLAYER_H
        for f in range(FRAMES):
            fx = f * PLAYER_W
            phase = (f == 1)        # в среднем кадре шаг: ноги поочерёдно приподняты
            lift_l = -1 if (phase and f == 1) else 0
            lift_r = -1 if (phase and f == 2) else 0
            bob_y = -1 if f == 1 else 0
            top = y0 + bob_y

            # голова
            d.rectangle([fx + 4, top + 1, fx + 11, top + 7], fill=skin)
            d.rectangle([fx + 4, top + 1, fx + 11, top + 2], fill=hair)  # макушка
            if row == "up":
                d.rectangle([fx + 4, top + 3, fx + 11, top + 5], fill=hair)  # затылок
            elif row == "down":
                d.rectangle([fx + 6, top + 4, fx + 6, top + 5], fill=eye)
                d.rectangle([fx + 9, top + 4, fx + 9, top + 5], fill=eye)
            elif row == "left":
                d.rectangle([fx + 5, top + 4, fx + 5, top + 5], fill=eye)
            elif row == "right":
                d.rectangle([fx + 10, top + 4, fx + 10, top + 5], fill=eye)

            # тело
            d.rectangle([fx + 4, top + 8, fx + 11, top + 13], fill=body)
            # руки (в фазе шага противоположно ногам)
            arm_dy = 1 if f == 1 else 0
            d.rectangle([fx + 2, top + 8 + arm_dy, fx + 3, top + 12 + arm_dy], fill=skin)
            d.rectangle([fx + 12, top + 8 - arm_dy, fx + 13, top + 12 - arm_dy], fill=skin)
            # ноги
            d.rectangle([fx + 5, top + 14 + lift_l, fx + 6, top + 17], fill=leg)
            d.rectangle([fx + 9, top + 14 + lift_r, fx + 10, top + 17], fill=leg)
            d.rectangle([fx + 5, top + 18, fx + 6, top + 18], fill=boot)
            d.rectangle([fx + 9, top + 18, fx + 10, top + 18], fill=boot)

    img.save(path)


def speckle(d: ImageDraw.ImageDraw, x0: int, size: int, base, variance: int, seed: int) -> None:
    """Детерминированные пиксельные крапинки поверх плашки цвета."""
    rnd = random.Random(seed)
    for _ in range(size * size // 6):
        x = x0 + rnd.randrange(size)
        y = rnd.randrange(size)
        v = rnd.randint(-variance, variance)
        c = tuple(max(0, min(255, ch + v)) for ch in base) + (255,)
        d.point((x, y), fill=c)


def gen_tiles(path: str) -> None:
    img = Image.new("RGBA", (TILE * 3, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # атлас 0: трава
    d.rectangle([0, 0, TILE - 1, TILE - 1], fill=(76, 140, 60, 255))
    speckle(d, 0, TILE, (76, 140, 60), 22, 1)
    rnd = random.Random(7)
    for _ in range(14):  # травинки
        x = rnd.randrange(1, TILE - 1)
        y = rnd.randrange(2, TILE - 1)
        d.point((x, y), fill=(104, 172, 82, 255))
        d.point((x, y - 1), fill=(104, 172, 82, 255))

    # атлас 1: камень
    x0 = TILE
    d.rectangle([x0, 0, x0 + TILE - 1, TILE - 1], fill=(128, 128, 134, 255))
    speckle(d, x0, TILE, (128, 128, 134), 20, 2)
    d.line([x0 + 4, 10, x0 + 14, 14, x0 + 24, 8], fill=(90, 90, 96, 255))
    d.line([x0 + 8, 24, x0 + 18, 20], fill=(90, 90, 96, 255))

    # атлас 2: вода
    x0 = TILE * 2
    d.rectangle([x0, 0, x0 + TILE - 1, TILE - 1], fill=(48, 96, 176, 255))
    speckle(d, x0, TILE, (48, 96, 176), 16, 3)
    for yy in (8, 16, 24):
        d.line([x0 + 4, yy, x0 + 10, yy - 2, x0 + 16, yy, x0 + 22, yy - 2, x0 + 28, yy],
               fill=(96, 144, 216, 255))

    img.save(path)


def gen_missing(path: str) -> None:
    Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0)).save(path)


if __name__ == "__main__":
    os.makedirs("assets/sprites", exist_ok=True)
    os.makedirs("assets/tiles", exist_ok=True)
    gen_player("assets/sprites/player.png")
    gen_tiles("assets/tiles/grass_atlas.png")
    gen_missing("assets/tiles/missing_tile.png")
    print("OK: assets generated")
