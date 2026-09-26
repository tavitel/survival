#!/usr/bin/env python3
"""Генерация стартовых ассетов для проекта (запускается один раз разработчиком).

Создаёт:
  assets/sprites/player.png        - атлас персонажа, 4 ряда (down/left/right/up) x 3 кадра, 16x20 на кадр
  assets/sprites/tree.png          - спрайт дерева 32x48 (одна анимация удара: 3 кадра в ряд)
  assets/sprites/items.png         - атлас предметов 16x16: топор, бревно (строки), целость/поломка (столбцы)
  assets/tiles/landscape_atlas.png - атлас ландшафта 32x32: земля(0) / камень(1) / вода(2)
  assets/tiles/missing_tile.png    - полностью прозрачная "отсутствующая" плитка
"""
import os
import random

from PIL import Image, ImageDraw

TILE = 32
ITEM = 16
PLAYER_W, PLAYER_H = 16, 20
TREE_W, TREE_H = 32, 48
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
    """Атлас ландшафта: столбцы-атласы 0=земля, 1=камень, 2=вода."""
    img = Image.new("RGBA", (TILE * 3, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # атлас 0: земля (почва с комьями)
    d.rectangle([0, 0, TILE - 1, TILE - 1], fill=(134, 96, 58, 255))
    speckle(d, 0, TILE, (134, 96, 58), 24, 1)
    rnd = random.Random(7)
    for _ in range(10):  # комья земли
        x = rnd.randrange(2, TILE - 4)
        y = rnd.randrange(2, TILE - 4)
        w = rnd.randint(2, 4)
        d.rectangle([x, y, x + w, y + max(1, w - 2)], fill=(104, 72, 42, 255))
        d.point((x, y - 1), fill=(158, 118, 74, 255))
    for _ in range(8):  # мелкие камушки
        x = rnd.randrange(1, TILE - 2)
        y = rnd.randrange(1, TILE - 2)
        d.rectangle([x, y, x + 1, y], fill=(150, 150, 140, 255))

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


def gen_tree(path: str) -> None:
    """Спрайт дерева 32x48; кадры "удара" (тряска) — подряд в ряд: 3 кадра."""
    W, H = TREE_W * FRAMES, TREE_H
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    trunk = (104, 70, 40, 255)
    trunk_d = (78, 50, 28, 255)
    leaf = (44, 108, 44, 255)
    leaf_l = (70, 140, 62, 255)
    leaf_d = (30, 82, 34, 255)

    for f in range(FRAMES):
        ox = f * TREE_W
        shake = [0, 1, -1][f]  # средний кадр — наклон вбок (отклик на удар)
        d = ImageDraw.Draw(img)
        # ствол
        tx = ox + 13 + (shake // 2 if f else 0)
        d.rectangle([tx, 26, tx + 5, 46], fill=trunk)
        d.rectangle([tx, 26, tx + 1, 46], fill=trunk_d)
        d.rectangle([tx - 2, 44, tx + 7, 46], fill=trunk_d)  # основание
        # крона (три плашки)
        cx = ox + 15 + shake
        blobs = [(cx, 4, 22, 18), (cx - 8, 12, 20, 16), (cx + 6, 12, 20, 16)]
        for bx, by, bw, bh in blobs:
            d.rectangle([bx, by, bx + bw, by + bh], fill=leaf)
        # блики/тени на кроне
        for bx, by, bw, bh in blobs:
            d.rectangle([bx + 2, by + 2, bx + bw - 6, by + 5], fill=leaf_l)
            d.rectangle([bx + 2, by + bh - 3, bx + bw - 2, by + bh - 1], fill=leaf_d)
    img.save(path)


def gen_items(path: str) -> None:
    """Атлас предметов 16x16: строки axe/log, столбцы: 0=целый, 1=сломанный."""
    img = Image.new("RGBA", (ITEM * 2, ITEM * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def draw_axe(x0: int, broken: bool) -> None:
        handle = (120, 82, 46, 255)
        head = (150, 152, 160, 255)
        edge = (200, 202, 210, 255)
        # рукоять по диагонали
        for i in range(9):
            d.rectangle([x0 + 3 + i, 14 - i, x0 + 4 + i, 15 - i], fill=handle)
        # головка топора
        hx, hy = x0 + 8, 3
        d.rectangle([hx, hy, hx + 5, hy + 5], fill=head)
        d.polygon([(x0 + 4, hy - 1), (x0 + 4, hy + 7), (x0 + 1, hy + 5), (x0 + 1, hy + 1)], fill=edge)
        if broken:
            # трещина + отколотый кусок
            d.line([(x0 + 9, hy), (x0 + 12, hy + 5)], fill=(60, 60, 66, 255))
            d.point((x0 + 13, hy + 6), fill=head)
            d.point((x0 + 2, hy - 1), fill=edge)
        else:
            d.rectangle([hx, hy, hx + 5, hy], fill=(110, 112, 120, 255))

    def draw_log(x0: int) -> None:
        bark = (112, 76, 44, 255)
        bark_d = (84, 56, 32, 255)
        wood = (196, 156, 100, 255)
        d.rectangle([x0 + 1, 5, x0 + 12, 11], fill=bark)          # бок бревна
        d.rectangle([x0 + 1, 5, x0 + 12, 6], fill=bark_d)         # верхняя грань
        d.rectangle([x0 + 1, 10, x0 + 12, 11], fill=bark_d)       # нижняя грань
        d.ellipse([x0 + 10, 4, x0 + 15, 12], fill=wood)           # торец
        d.ellipse([x0 + 11, 6, x0 + 14, 10], fill=bark_d)         # годовые кольца
        d.point((x0 + 12, 8), fill=wood)
        d.point((x0 + 4, 8), fill=bark_d)
        d.point((x0 + 7, 9), fill=bark_d)

    draw_axe(0, False)          # строка 0, атлас 0: топор целый
    draw_axe(ITEM, True)        # строка 0, атлас 1: топор сломанный
    draw_log(0)                 # строка 1, атлас 0: бревно
    draw_log(ITEM)              # строка 1, атлас 1: (не используется) тот же вид

    img.save(path)


def gen_missing(path: str) -> None:
    Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0)).save(path)


if __name__ == "__main__":
    os.makedirs("assets/sprites", exist_ok=True)
    os.makedirs("assets/tiles", exist_ok=True)
    gen_player("assets/sprites/player.png")
    gen_tree("assets/sprites/tree.png")
    gen_items("assets/sprites/items.png")
    gen_tiles("assets/tiles/landscape_atlas.png")
    gen_missing("assets/tiles/missing_tile.png")
    print("OK: assets generated")
