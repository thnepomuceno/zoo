"""Gera os áudios da narração a partir de godot/assets/narracao/roteiro.json.

Uso:
    pip install edge-tts truststore
    python tools/gerar_narracao.py                     # voz padrão
    python tools/gerar_narracao.py --voz pt-BR-ThalitaMultilingualNeural --velocidade +15%

Precisa de internet apenas para gerar. O jogo toca os .mp3 sem conexão.
Se um .mp3 não existir, o jogo usa a voz portuguesa do Windows.
"""
import argparse
import asyncio
import json
from pathlib import Path

try:  # Redes corporativas com inspeção de SSL: usa os certificados do Windows.
    import truststore

    truststore.inject_into_ssl()
except ImportError:
    pass

import edge_tts

PASTA = Path(__file__).resolve().parent.parent / "godot" / "assets" / "narracao"


async def gerar(voz: str, velocidade: str, tom: str, apenas: list[str]) -> None:
    roteiro = json.loads((PASTA / "roteiro.json").read_text(encoding="utf-8"))
    for chave, texto in roteiro.items():
        if apenas and chave not in apenas:
            continue
        destino = PASTA / f"{chave}.mp3"
        await edge_tts.Communicate(texto, voz, rate=velocidade, pitch=tom).save(str(destino))
        print("ok", destino.name)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--voz", default="pt-BR-FranciscaNeural")
    p.add_argument("--velocidade", default="+12%")
    p.add_argument("--tom", default="+4Hz")
    p.add_argument("chaves", nargs="*", help="gera só estas falas")
    a = p.parse_args()
    asyncio.run(gerar(a.voz, a.velocidade, a.tom, a.chaves))
