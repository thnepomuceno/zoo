"""Gera um .mp3 de uma frase livre com a mesma voz da narração.

O jogo chama este script na hora de apresentar os nomes que as crianças escreveram,
para que a voz não troque. Precisa de internet e de `pip install edge-tts truststore`;
se falhar, o jogo usa a voz do sistema.

Uso: python tools/falar_frase.py "A capivara se chama Luna!" saida.mp3
"""
import asyncio
import sys

from gerar_narracao import TOM, VELOCIDADE, VOZ, edge_tts

if __name__ == "__main__":
    texto, destino = sys.argv[1], sys.argv[2]
    asyncio.run(edge_tts.Communicate(texto, VOZ, rate=VELOCIDADE, pitch=TOM).save(destino))
