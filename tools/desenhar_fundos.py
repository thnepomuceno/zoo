"""Desenha os fundos da Lagoa Cristalina e da Aventura Marinha (estilo aquarela de livro infantil).

Uso:
    pip install pillow numpy scipy
    python tools/desenhar_fundos.py            # os dois
    python tools/desenhar_fundos.py lagoa      # só um

As coordenadas são as da tela do jogo (1152 x 648). A imagem sai com 1,5x esse tamanho.
Os animais ficam em x = 150, 405, 660 e 915, com as patas por volta de y = 475,
e o ajudante à direita (x ~ 1080), por isso essas áreas ficam mais limpas.
"""
import math
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as nd

RAIZ = Path(__file__).resolve().parent.parent / "godot" / "assets"
W, H = 1152, 648
SS = 3  # desenha em 3x e reduz para 1,5x (bordas suaves)
SAIDA = 1.5
TRACO = (58, 52, 66)


def k(v):
    return int(round(v * SS))


def pts(lista):
    return [(k(x), k(y)) for x, y in lista]


def ruido(w, h, escala, semente):
    rng = np.random.default_rng(semente)
    r = rng.random((h // escala + 2, w // escala + 2))
    r = nd.zoom(r, escala, order=3)[:h, :w]
    return (r - r.min()) / (np.ptp(r) + 1e-6)


def gradiente(img, cores, y0, y1, x0=0, x1=W):
    """Gradiente vertical de várias cores entre y0 e y1."""
    d = ImageDraw.Draw(img)
    for y in range(k(y0), k(y1)):
        t = (y - k(y0)) / max(k(y1) - k(y0) - 1, 1)
        n = len(cores) - 1
        i = min(int(t * n), n - 1)
        f = t * n - i
        c = tuple(int(cores[i][j] + (cores[i + 1][j] - cores[i][j]) * f) for j in range(3))
        d.line([(k(x0), y), (k(x1), y)], fill=c)


def camada():
    return Image.new("RGBA", (k(W), k(H)), (0, 0, 0, 0))


def colar(base, cam, sombra=False):
    if sombra:
        a = cam.split()[3].filter(ImageFilter.GaussianBlur(k(4)))
        s = Image.new("RGBA", cam.size, (30, 30, 60, 0))
        s.putalpha(a.point(lambda v: v * 0.25))
        base.alpha_composite(s, (k(3), k(5)))
    base.alpha_composite(cam)


def forma(d, xy, cor, contorno=TRACO, largura=2.2, tipo="poligono"):
    if tipo == "poligono":
        d.polygon(pts(xy), fill=cor)
        if contorno:
            d.line(pts(xy + [xy[0]]), fill=contorno, width=k(largura), joint="curve")
    elif tipo == "elipse":
        x0, y0, x1, y1 = xy
        d.ellipse([k(x0), k(y0), k(x1), k(y1)], fill=cor, outline=contorno, width=k(largura) if contorno else 0)


def curva(p0, p1, p2, n=24):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]) for t in (i / n for i in range(n + 1))]


def blob(cx, cy, rx, ry, semente, irregular=0.12, n=48):
    rng = random.Random(semente)
    fases = [rng.random() * 6.28 for _ in range(3)]
    lista = []
    for i in range(n):
        a = i / n * math.tau
        r = 1 + irregular * (math.sin(a * 3 + fases[0]) * 0.5 + math.sin(a * 5 + fases[1]) * 0.3 + math.sin(a * 7 + fases[2]) * 0.2)
        lista.append((cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r))
    return lista


def aquarela(img, semente):
    """Papel e manchas de aquarela: varia um pouco o tom e escurece as bordas das manchas."""
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w = a.shape[:2]
    n1 = ruido(w, h, k(60), semente)
    n2 = ruido(w, h, k(9), semente + 1)
    fator = 0.93 + 0.1 * n1[..., None] + 0.04 * (n2[..., None] - 0.5)
    a = np.clip(a * fator, 0, 255)
    papel = np.random.default_rng(semente).normal(0, 3.0, (h, w, 1))
    a = np.clip(a + papel, 0, 255).astype(np.uint8)
    return Image.fromarray(a)


def salvar(img, caminho):
    img = img.resize((int(W * SAIDA), int(H * SAIDA)), Image.LANCZOS)
    caminho.parent.mkdir(parents=True, exist_ok=True)
    img.save(caminho, optimize=True)
    print("ok", caminho)


# ------------------------------------------------------------------ peças comuns

def nuvenzinha(d, cx, cy, s):
    for dx, dy, r in [(-40, 6, 26), (-12, -10, 34), (22, -4, 30), (48, 8, 22), (0, 12, 30)]:
        forma(d, [cx + (dx - r) * s, cy + (dy - r) * s, cx + (dx + r) * s, cy + (dy + r) * s], (255, 252, 246), None, tipo="elipse")
    d.line(pts(curva((cx - 66 * s, cy + 24 * s), (cx, cy + 34 * s), (cx + 70 * s, cy + 24 * s))), fill=(214, 222, 236), width=k(3))


def sol(img, cx, cy, r):
    cam = camada()
    d = ImageDraw.Draw(cam)
    for i in range(16):
        a = i / 16 * math.tau
        p1 = (cx + math.cos(a - 0.09) * r * 1.25, cy + math.sin(a - 0.09) * r * 1.25)
        p2 = (cx + math.cos(a) * r * (2.6 if i % 2 else 2.1), cy + math.sin(a) * r * (2.6 if i % 2 else 2.1))
        p3 = (cx + math.cos(a + 0.09) * r * 1.25, cy + math.sin(a + 0.09) * r * 1.25)
        d.polygon(pts([p1, p2, p3]), fill=(255, 240, 170, 120))
    cam = cam.filter(ImageFilter.GaussianBlur(k(3)))
    img.alpha_composite(cam)
    d = ImageDraw.Draw(img)
    forma(d, [cx - r * 1.35, cy - r * 1.35, cx + r * 1.35, cy + r * 1.35], (255, 244, 190, 255), None, tipo="elipse")
    forma(d, [cx - r, cy - r, cx + r, cy + r], (255, 214, 70), (230, 160, 40), 2.5, tipo="elipse")
    forma(d, [cx - r * 0.7, cy - r * 0.75, cx + r * 0.35, cy + r * 0.2], (255, 232, 120), None, tipo="elipse")


def arvore(d, x, chao, alt, s, semente, verde=((96, 170, 78), (128, 196, 96))):
    rng = random.Random(semente)
    forma(d, [(x - 5 * s, chao), (x - 4 * s, chao - alt * 0.5), (x + 4 * s, chao - alt * 0.5), (x + 5 * s, chao)], (132, 92, 62), TRACO, 1.6)
    for j in range(4):
        cx = x + rng.uniform(-14, 14) * s
        cy = chao - alt * 0.55 - rng.uniform(0, alt * 0.35)
        r = rng.uniform(16, 24) * s
        forma(d, blob(cx, cy, r, r * 0.9, semente + j, 0.1), verde[j % 2], TRACO, 1.6)


def flor(d, x, y, cor, s=1.0):
    for a in range(5):
        ang = a / 5 * math.tau
        px, py = x + math.cos(ang) * 4.5 * s, y + math.sin(ang) * 4.5 * s
        forma(d, [px - 4 * s, py - 4 * s, px + 4 * s, py + 4 * s], cor, TRACO, 1.0, tipo="elipse")
    forma(d, [x - 3 * s, y - 3 * s, x + 3 * s, y + 3 * s], (255, 214, 70), None, tipo="elipse")


def tufo(d, x, y, alt, cor, n=7, semente=0):
    rng = random.Random(semente)
    for i in range(n):
        dx = (i - n / 2) * 3.2
        topo = (x + dx + rng.uniform(-8, 8), y - alt * rng.uniform(0.6, 1.0))
        d.line(pts(curva((x + dx, y), (x + dx * 0.6, y - alt * 0.5), topo, 8)), fill=cor, width=k(2.2))


def pedra(d, cx, cy, rx, ry, semente, cor=(150, 146, 140), musgo=None):
    contorno = blob(cx, cy, rx, ry, semente, 0.08)
    contorno = [(x, min(y, cy + ry * 0.55)) for x, y in contorno]
    forma(d, contorno, cor, TRACO, 2.2)
    claro = tuple(min(c + 30, 255) for c in cor)
    forma(d, blob(cx - rx * 0.25, cy - ry * 0.35, rx * 0.45, ry * 0.22, semente + 3, 0.1), claro, None)
    if musgo:
        forma(d, blob(cx + rx * 0.1, cy - ry * 0.55, rx * 0.55, ry * 0.16, semente + 5, 0.25), musgo, None)


# ------------------------------------------------------------------ Lagoa Cristalina

def lagoa():
    img = Image.new("RGBA", (k(W), k(H)), (255, 255, 255, 255))
    gradiente(img, [(126, 196, 236), (178, 222, 244), (236, 246, 240)], 0, 270)
    sol(img, 872, 104, 46)
    d = ImageDraw.Draw(img)
    nuvenzinha(d, 170, 70, 1.0)
    nuvenzinha(d, 560, 120, 0.7)
    nuvenzinha(d, 1080, 160, 0.55)

    # Morros ao longe, com a fábrica (de onde veio a sujeira) bem pequenininha à esquerda.
    fundo = camada()
    f = ImageDraw.Draw(fundo)
    morro = [(0, 250)] + curva((0, 250), (260, 170), (520, 236)) + curva((520, 236), (760, 196), (1152, 228)) + [(1152, 330), (0, 330)]
    forma(f, morro, (150, 200, 140), None)
    # fábrica
    forma(f, [(110, 236), (110, 196), (150, 210), (150, 196), (190, 210), (190, 196), (230, 210), (230, 236)], (176, 160, 150), TRACO, 1.6)
    forma(f, [(126, 200), (126, 150), (140, 150), (140, 205)], (160, 120, 110), TRACO, 1.6)
    forma(f, [(196, 204), (196, 162), (208, 162), (208, 207)], (160, 120, 110), TRACO, 1.6)
    for i, (x, y, r) in enumerate([(134, 138, 10), (142, 122, 13), (154, 104, 16), (202, 150, 8), (210, 136, 11)]):
        forma(f, blob(x, y, r, r * 0.8, i, 0.15), (196, 190, 196), None)
    for x in [118, 160, 200]:
        forma(f, [x, 218, x + 12, 228], (250, 230, 150), TRACO, 1.0, tipo="elipse")
    colar(img, fundo)
    d = ImageDraw.Draw(img)
    for i, x in enumerate([300, 345, 395, 610, 660, 960, 1010, 1060, 1110]):
        arvore(d, x, 258 + (i % 3) * 6, 70 + (i % 2) * 16, 1.0, 40 + i)
    morro2 = [(0, 300)] + curva((0, 300), (300, 246), (600, 290)) + curva((600, 290), (880, 250), (1152, 284)) + [(1152, 360), (0, 360)]
    forma(d, morro2, (118, 186, 104), TRACO, 2.2)
    d.rectangle([0, k(356), k(W), k(H)], fill=(118, 186, 104))
    for i in range(30):
        flor(d, 30 + i * 38 + (i % 3) * 7, 300 + (i % 4) * 9, [(255, 255, 255), (255, 214, 70), (244, 156, 190)][i % 3], 0.55)

    # A lagoa: água cristalina com reflexos, vitórias-régias e uma prainha na frente.
    agua = camada()
    a = ImageDraw.Draw(agua)
    lago = blob(576, 410, 700, 104, 7, 0.04, 96)
    forma(a, lago, (96, 176, 222), TRACO, 2.6)
    colar(img, agua)
    brilho = camada()
    b = ImageDraw.Draw(brilho)
    forma(b, blob(576, 392, 650, 74, 8, 0.04, 96), (150, 210, 240, 255), None)
    forma(b, blob(560, 372, 430, 40, 9, 0.06, 80), (196, 234, 250, 255), None)
    brilho = brilho.filter(ImageFilter.GaussianBlur(k(10)))
    mascara = Image.new("L", brilho.size, 0)
    ImageDraw.Draw(mascara).polygon(pts(lago), fill=255)
    brilho.putalpha(Image.fromarray(np.minimum(np.asarray(brilho.split()[3]), np.asarray(mascara))))
    img.alpha_composite(brilho)
    d = ImageDraw.Draw(img)
    # reflexo do sol e marolinhas
    for i in range(14):
        y = 330 + i * 9
        x = 860 + math.sin(i) * 14
        d.line(pts([(x - 34 + i, y), (x + 34 - i, y)]), fill=(255, 246, 200), width=k(2.2))
    rng = random.Random(3)
    for i in range(22):
        x, y = rng.uniform(80, 1100), rng.uniform(345, 470)
        largura = rng.uniform(16, 40)
        d.line(pts(curva((x - largura, y), (x, y - 4), (x + largura, y))), fill=(232, 248, 255), width=k(1.8))
    for i, (x, y, r) in enumerate([(282, 372, 26), (322, 392, 18), (520, 352, 22), (775, 382, 28), (818, 360, 16), (1010, 398, 24)]):
        folha = blob(x, y, r, r * 0.42, 20 + i, 0.04)
        forma(d, folha, (98, 178, 86), TRACO, 1.8)
        d.polygon(pts([(x, y), (x + r * 1.05, y - r * 0.12), (x + r * 1.05, y + r * 0.12)]), fill=(96, 176, 222))
        d.line(pts([(x, y), (x - r * 0.6, y - r * 0.2)]), fill=(70, 140, 70), width=k(1.4))
        if i % 2 == 0:
            for p in range(6):
                ang = p / 6 * math.pi + math.pi
                forma(d, [(x - 2, y - 2), (x + math.cos(ang) * 11 - 3, y + math.sin(ang) * 13), (x + math.cos(ang) * 11 + 3, y + math.sin(ang) * 13)], (246, 160, 196), TRACO, 1.2)
            forma(d, [x - 3, y - 6, x + 3, y], (255, 214, 70), None, tipo="elipse")

    # Prainha e grama da frente (onde os animais ficam).
    margem = [(0, 470)] + curva((0, 470), (300, 450), (600, 478)) + curva((600, 478), (880, 500), (1152, 462)) + [(1152, 648), (0, 648)]
    forma(d, margem, (232, 210, 160), TRACO, 2.4)
    grama = [(0, 520)] + curva((0, 520), (260, 494), (560, 536)) + curva((560, 536), (860, 560), (1152, 512)) + [(1152, 648), (0, 648)]
    forma(d, grama, (126, 196, 100), TRACO, 2.4)
    forma(d, [(0, 600)] + curva((0, 600), (500, 566), (1152, 590)) + [(1152, 648), (0, 648)], (106, 180, 86), None)
    rng = random.Random(5)
    for i in range(60):
        x = rng.uniform(0, 1152)
        y = rng.uniform(540, 640)
        tufo(d, x, y, rng.uniform(10, 20), (78, 150, 66), 5, i)
    for i in range(26):
        flor(d, rng.uniform(10, 1140), rng.uniform(560, 636), [(255, 255, 255), (255, 214, 70), (244, 156, 190), (172, 134, 220)][i % 4], 0.9)
    for i, (x, y) in enumerate([(40, 486), (520, 480), (780, 500), (1150, 470)]):
        pedra(d, x, y, 22, 14, 60 + i, (168, 160, 150))

    # Taboas (juncos) nas pontas, emoldurando a cena.
    for base_x, lado in [(30, 1), (1120, -1)]:
        for i in range(7):
            x = base_x + lado * i * 11
            topo = 300 + (i % 3) * 22
            haste = curva((x, 560), (x + lado * 6, (560 + topo) / 2), (x + lado * (4 + i), topo), 12)
            d.line(pts(haste), fill=(70, 140, 70), width=k(3))
            if i % 2 == 0:
                tx, ty = haste[-3]
                forma(d, [tx - 5, ty - 4, tx + 5, ty + 26], (150, 96, 60), TRACO, 1.4, tipo="elipse")
        for i in range(6):
            x = base_x + lado * i * 13
            folha = [(x, 562), (x + lado * (18 + i * 4), 420 + i * 16), (x + lado * 6, 562)]
            forma(d, folha, (96, 170, 80), TRACO, 1.4)

    img = aquarela(img, 11)
    salvar(img, RAIZ / "lagoa" / "lagoa.png")


# ------------------------------------------------------------------ Aventura Marinha

def marinha():
    img = Image.new("RGBA", (k(W), k(H)), (255, 255, 255, 255))
    gradiente(img, [(150, 222, 244), (70, 170, 220), (36, 118, 186), (28, 88, 156)], 0, 648)
    # Superfície lá em cima, com o sol entrando na água.
    d = ImageDraw.Draw(img)
    sup = [(0, 0), (1152, 0), (1152, 26)]
    for i in range(48, -1, -1):
        x = i * 24
        sup.append((x, 26 + math.sin(i * 1.3) * 5))
    forma(d, sup, (196, 240, 252), (120, 200, 236), 2.0)
    raios = camada()
    r = ImageDraw.Draw(raios)
    for i, (x, w) in enumerate([(640, 50), (760, 34), (860, 70), (980, 40), (1080, 56), (520, 30)]):
        r.polygon(pts([(x - w / 2, 20), (x + w / 2, 20), (x - 160 + w, 560), (x - 240, 560)]), fill=(230, 252, 255, 60))
    raios = raios.filter(ImageFilter.GaussianBlur(k(8)))
    img.alpha_composite(raios)
    brilho = camada()
    ImageDraw.Draw(brilho).ellipse([k(800), k(-60), k(920), k(60)], fill=(255, 250, 210, 230))
    img.alpha_composite(brilho.filter(ImageFilter.GaussianBlur(k(16))))

    # Recife ao longe (silhueta clarinha), depois pedras, corais e algas.
    longe = camada()
    l = ImageDraw.Draw(longe)
    perfil = [(0, 420)]
    rng = random.Random(9)
    for i in range(25):
        perfil.append((i * 48, 400 - rng.uniform(0, 60) - (40 if i % 6 == 2 else 0)))
    perfil += [(1152, 420), (1152, 520), (0, 520)]
    l.polygon(pts(perfil), fill=(80, 150, 200, 255))
    for i in range(14):
        x = rng.uniform(0, 1152)
        alt = rng.uniform(60, 140)
        for j in range(3):
            l.line(pts(curva((x + j * 6, 430), (x + j * 6 + 18, 430 - alt / 2), (x + j * 6 - 4, 430 - alt))), fill=(70, 140, 190, 255), width=k(4))
    colar(img, longe)
    d = ImageDraw.Draw(img)

    # Areia do fundo.
    areia = [(0, 480)] + curva((0, 480), (300, 458), (620, 486)) + curva((620, 486), (900, 506), (1152, 470)) + [(1152, 648), (0, 648)]
    forma(d, areia, (238, 216, 164), TRACO, 2.4)
    forma(d, [(0, 560)] + curva((0, 560), (560, 530), (1152, 556)) + [(1152, 648), (0, 648)], (226, 200, 146), None)
    rng = random.Random(4)
    for i in range(40):
        x, y = rng.uniform(0, 1152), rng.uniform(500, 640)
        d.line(pts(curva((x - 18, y), (x, y - 4), (x + 18, y))), fill=(206, 180, 130), width=k(1.6))

    def alga(x, base, alt, cor, semente, largura=7):
        rng2 = random.Random(semente)
        fase = rng2.random() * 6
        pontos_e, pontos_d = [], []
        for j in range(21):
            t = j / 20
            y = base - alt * t
            cx = x + math.sin(t * 5 + fase) * 12 * t
            w = largura * (1 - t * 0.7)
            pontos_e.append((cx - w, y))
            pontos_d.append((cx + w, y))
        forma(d, pontos_e + pontos_d[::-1], cor, TRACO, 1.8)
        for j in range(3, 18, 4):
            t = j / 20
            cx = x + math.sin(t * 5 + fase) * 12 * t
            lado = 1 if j % 8 == 3 else -1
            y = base - alt * t
            folha = [(cx + lado * (3 + 24 * u), y - 16 * u - math.sin(u * math.pi) * 6) for u in np.linspace(0, 1, 10)]
            folha += [(cx + lado * (3 + 24 * u), y - 16 * u + math.sin(u * math.pi) * 6) for u in np.linspace(1, 0, 10)]
            forma(d, folha, cor, TRACO, 1.4)

    def coral(x, base, alt, cor, semente):
        rng2 = random.Random(semente)

        def galho(px, py, ang, comp, esp, n):
            qx, qy = px + math.cos(ang) * comp, py + math.sin(ang) * comp
            d.line(pts([(px, py), (qx, qy)]), fill=TRACO, width=k(esp + 3))
            d.line(pts([(px, py), (qx, qy)]), fill=cor, width=k(esp))
            forma(d, [qx - esp / 2 - 1, qy - esp / 2 - 1, qx + esp / 2 + 1, qy + esp / 2 + 1], cor, TRACO, 1.2, tipo="elipse")
            if n > 0:
                for da in (-0.5, 0.45):
                    galho(qx, qy, ang + da + rng2.uniform(-0.15, 0.15), comp * 0.72, esp * 0.75, n - 1)

        galho(x, base, -math.pi / 2, alt * 0.38, 10, 3)

    def leque(x, base, r, cor, semente):
        lista = [(x, base)] + [(x + math.cos(a) * r, base - math.sin(a) * r * 1.1) for a in np.linspace(0.25, math.pi - 0.25, 20)]
        forma(d, lista, cor, TRACO, 2.0)
        for a in np.linspace(0.4, math.pi - 0.4, 7):
            d.line(pts([(x, base), (x + math.cos(a) * r * 0.9, base - math.sin(a) * r)]), fill=tuple(max(c - 40, 0) for c in cor), width=k(1.6))

    # Fundo esquerdo e direito: pedras grandes com corais e algas (o Polvo fica nas da direita).
    for i, (x, h_) in enumerate([(30, 260), (64, 200), (100, 290), (1004, 230), (1040, 300), (1136, 250), (560, 180), (300, 160), (800, 170)]):
        alga(x, 500, h_, [(84, 170, 96), (110, 190, 90), (60, 150, 110)][i % 3], i)
    torre = [(x, y) for x, y in blob(1092, 420, 112, 120, 1, 0.07, 64)]
    forma(d, torre, (128, 132, 150), TRACO, 2.4)
    forma(d, blob(1070, 330, 70, 22, 4, 0.1), (150, 154, 170), None)
    forma(d, blob(1100, 318, 60, 12, 5, 0.25), (110, 170, 120), None)
    for i, (x, y) in enumerate([(1010, 420), (1110, 380), (1060, 460)]):
        forma(d, blob(x, y, 18, 10, 30 + i, 0.2), (112, 116, 134), None)
    pedra(d, 60, 470, 110, 60, 2, (138, 134, 150), (110, 170, 120))
    coral(240, 500, 150, (244, 132, 150), 1)
    coral(520, 492, 120, (255, 160, 90), 2)
    coral(760, 506, 136, (186, 130, 220), 3)
    leque(360, 498, 56, (238, 106, 120), 4)
    leque(890, 500, 48, (255, 196, 90), 5)
    coral(980, 504, 110, (255, 120, 120), 6)
    for i, (x, y, cor) in enumerate([(140, 560, (255, 150, 90)), (470, 600, (244, 120, 150)), (700, 570, (255, 190, 80)), (1000, 610, (190, 140, 230))]):
        # estrelas-do-mar
        lista = []
        for p in range(10):
            ang = p / 10 * math.tau - math.pi / 2
            rr = 16 if p % 2 == 0 else 7
            lista.append((x + math.cos(ang) * rr, y + math.sin(ang) * rr))
        forma(d, lista, cor, TRACO, 1.6)
    for i, (x, y) in enumerate([(300, 620), (620, 560), (860, 630), (1100, 580)]):
        # conchinhas
        forma(d, [(x - 12, y), (x, y - 14), (x + 12, y)], (255, 226, 214), TRACO, 1.4)
        for j in (-6, 0, 6):
            d.line(pts([(x, y - 12), (x + j, y)]), fill=(220, 170, 160), width=k(1.2))
    # bolhas
    rng = random.Random(8)
    for i in range(36):
        x, y, rr = rng.uniform(0, 1152), rng.uniform(60, 460), rng.uniform(3, 9)
        forma(d, [x - rr, y - rr, x + rr, y + rr], (200, 240, 255), (240, 252, 255), 1.4, tipo="elipse")
        forma(d, [x - rr * 0.5, y - rr * 0.6, x - rr * 0.1, y - rr * 0.2], (255, 255, 255), None, tipo="elipse")
    # peixinhos ao longe
    for i, (x, y, cor) in enumerate([(300, 150, (255, 210, 90)), (330, 170, (255, 210, 90)), (280, 180, (255, 210, 90)), (620, 240, (250, 150, 120)), (650, 226, (250, 150, 120))]):
        forma(d, [x - 10, y - 5, x + 8, y + 5], cor, TRACO, 1.2, tipo="elipse")
        forma(d, [(x + 6, y), (x + 15, y - 6), (x + 15, y + 6)], cor, TRACO, 1.2)

    img = aquarela(img, 21)
    salvar(img, RAIZ / "marinha" / "marinha.png")


if __name__ == "__main__":
    pedidos = sys.argv[1:] or ["lagoa", "marinha"]
    if "lagoa" in pedidos:
        lagoa()
    if "marinha" in pedidos:
        marinha()
