"""Transforma a folha de cartões (PDF "8x8 4 na folha") nas imagens dos animais do jogo.

Para cada cartão gera, em godot/assets/animais:
    <nome>.png          desenho com fundo transparente (linhas pretas, miolo branco)
    <nome>_regioes.png  mapa das regiões pintáveis (0 = cor 1, 85 = cor 2, 170 = cor 3,
                        255 = fica branco, como o brilho dos olhos)

Uso (nomes na ordem dos cartões: cima-esq, cima-dir, baixo-esq, baixo-dir; nas folhas
"uma por folha", na ordem das páginas):
    pip install pypdf pillow numpy scipy
    python tools/preparar_animais.py floresta_encantada_8x8_4_na_folha_v2.pdf macaco borboleta tamandua onca
    python tools/preparar_animais.py fazenda_feliz_8x8_4_na_folha.pdf cavalo porco pato galinha
    python tools/preparar_animais.py "lagoa_cristalina_8x8_uma_por_folha (1).pdf" sapo peixe_lagoa capivara cobra
    python tools/preparar_animais.py aventura_marinha_8x8_uma_por_folha.pdf baleia peixe_mar tartaruga boto
"""
import io
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from pypdf import PdfReader
from scipy import ndimage as nd

DESTINO = Path(__file__).resolve().parent.parent / "godot" / "assets" / "animais"
LADO = 512  # maior lado da imagem final, em pixels
# Área do desenho de cada cartão na folha A4, em pontos (sem cabeçalho e sem o nome).
CAIXAS = [(57, 152, 278, 376), (318, 152, 539, 376), (57, 465, 278, 689), (318, 465, 539, 689)]
CAIXA_UNICA = (186, 309, 409, 533)  # folhas "uma por folha": um cartão no meio da página


def preparar(g: np.ndarray, nome: str) -> None:
    linha = g < 140
    # Fora do desenho: o branco ligado à borda. As linhas são engordadas para fechar frestas.
    rot, _ = nd.label(~nd.binary_dilation(linha, iterations=10))
    borda = set(np.unique(np.concatenate([rot[0], rot[-1], rot[:, 0], rot[:, -1]]))) - {0}
    fora = nd.binary_dilation(np.isin(rot, list(borda)), iterations=9) & ~linha
    dentro = nd.binary_fill_holes(~fora)
    # Faixa clara que sobra entre a linha de fora e o recorte: transparente, com borda suave.
    claro, _ = nd.label(dentro & (g >= 140))
    ids = np.unique(claro[nd.binary_dilation(fora, iterations=2) & (claro > 0)])
    tamanhos = nd.sum(np.ones_like(claro), claro, index=ids) if len(ids) else []
    aro = np.isin(claro, [i for i, t in zip(ids, tamanhos) if t < dentro.sum() * 0.03])
    suave = np.clip((255 - g) / 115.0, 0, 1)

    # Regiões brancas entre as linhas: as maiores recebem as cores 1, 2 e 3 alternadas.
    reg, qtd = nd.label(dentro & ~nd.binary_dilation(linha, iterations=3))
    areas = nd.sum(np.ones_like(reg), reg, index=np.arange(1, qtd + 1))
    grandes = [i for i in np.argsort(-areas) if areas[i] > dentro.sum() * 0.004]
    classe = np.full(reg.shape, 255, np.uint8)
    for pos, i in enumerate(grandes):
        classe[reg == i + 1] = (0, 85, 170)[pos % 3]
    # Linhas e frestas herdam a classe da região mais próxima (sem halos ao filtrar).
    rotulada = np.isin(reg, [i + 1 for i in grandes])
    _, (iy, ix) = nd.distance_transform_edt(~rotulada, return_indices=True)
    classe = np.where(rotulada | (reg == 0), classe[iy, ix], classe)

    ys, xs = np.where(dentro & ~aro)
    m = 12
    y0, x0 = max(ys.min() - m, 0), max(xs.min() - m, 0)
    y1, x1 = min(ys.max() + 1 + m, g.shape[0]), min(xs.max() + 1 + m, g.shape[1])
    lum = np.where(aro, 0, np.where(dentro, g, 255))[y0:y1, x0:x1].astype(np.uint8)
    alfa = (np.where(aro, suave, dentro * 1.0) * 255).astype(np.uint8)[y0:y1, x0:x1]
    h, w = lum.shape
    k = LADO / max(h, w)
    tam = (round(w * k), round(h * k))
    L = Image.fromarray(lum).resize(tam, Image.LANCZOS)
    A = Image.fromarray(alfa).resize(tam, Image.LANCZOS)
    Image.merge("RGBA", (L, L, L, A)).save(DESTINO / f"{nome}.png")
    Image.fromarray(classe[y0:y1, x0:x1]).resize(tam, Image.NEAREST).save(DESTINO / f"{nome}_regioes.png")
    print("ok", nome, tam, "regiões:", len(grandes))


def main() -> None:
    if len(sys.argv) != 6:
        sys.exit(__doc__)
    paginas = PdfReader(sys.argv[1]).pages
    DESTINO.mkdir(parents=True, exist_ok=True)
    # Uma folha com 4 cartões, ou 4 folhas com um cartão cada.
    cartoes = [(0, c) for c in CAIXAS] if len(paginas) == 1 else [(i, CAIXA_UNICA) for i in range(4)]
    for nome, (i, caixa) in zip(sys.argv[2:], cartoes):
        folha = Image.open(io.BytesIO(paginas[i].images[0].data)).convert("L")
        k = folha.width / float(paginas[i].mediabox.width)
        recorte = folha.crop(tuple(int(v * k) for v in caixa))
        preparar(np.asarray(recorte).astype(np.float32), nome)


if __name__ == "__main__":
    main()
