"""Sintetiza os efeitos sonoros originais do jogo (sem amostras externas).

    python tools/gerar_efeitos.py
"""
import wave
from pathlib import Path

import numpy as np

TAXA = 44100
PASTA = Path(__file__).resolve().parent.parent / "godot" / "assets" / "audio"
rng = np.random.default_rng(7)


def salvar(nome: str, sinal: np.ndarray) -> None:
    sinal = sinal / (np.max(np.abs(sinal)) + 1e-9) * 0.85
    dados = (sinal * 32767).astype(np.int16)
    with wave.open(str(PASTA / nome), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(dados.tobytes())
    print("ok", nome)


def tempo(seg: float) -> np.ndarray:
    return np.arange(int(TAXA * seg)) / TAXA


def passa_baixa(x: np.ndarray, corte: np.ndarray | float) -> np.ndarray:
    alfa = (1.0 - np.exp(-2 * np.pi * np.broadcast_to(corte, x.shape) / TAXA)).tolist()
    y = [0.0] * len(x)
    acc = 0.0
    for i, v in enumerate(x.tolist()):
        acc += alfa[i] * (v - acc)
        y[i] = acc
    return np.array(y)


def magia() -> np.ndarray:
    """Arpejo cintilante subindo (dó maior pentatônico) com brilho."""
    t = tempo(2.2)
    s = np.zeros_like(t)
    notas = [523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0, 2093.0]
    for i, f in enumerate(notas):
        ini = i * 0.09
        tt = np.clip(t - ini, 0, None)
        env = np.where(t >= ini, np.exp(-tt * 3.2), 0) * np.minimum(tt * 200, 1)
        s += env * (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(2 * np.pi * f * 2.01 * tt))
    brilho = rng.standard_normal(len(t)) * (rng.random(len(t)) > 0.9985)
    brilho = np.convolve(brilho, np.exp(-np.arange(400) / 60), "same")
    s += 0.25 * brilho * np.sin(2 * np.pi * 5200 * t) * np.exp(-t * 1.2)
    return s


def sopro() -> np.ndarray:
    """Vento mágico: ruído que cresce e passa."""
    t = tempo(1.3)
    env = np.sin(np.pi * t / t[-1]) ** 2
    corte = 300 + 2500 * env
    return passa_baixa(rng.standard_normal(len(t)), corte) * env


def vento() -> np.ndarray:
    """Ambiente de vento suave, 12 s, com emenda contínua para repetir."""
    seg = 12.0
    t = tempo(seg)
    rajada = 0.55 + 0.3 * np.sin(2 * np.pi * t / seg) + 0.15 * np.sin(2 * np.pi * 3 * t / seg + 1)
    s = passa_baixa(rng.standard_normal(len(t)), 250 + 500 * rajada) * rajada
    n = int(TAXA * 1.5)  # emenda: mistura o fim no começo
    rampa = np.linspace(0, 1, n)
    s[:n] = s[:n] * rampa + s[-n:] * (1 - rampa)
    return s[:-n]


def pop() -> np.ndarray:
    t = tempo(0.25)
    f = 900 * np.exp(-t * 18) + 200
    return np.sin(2 * np.pi * np.cumsum(f) / TAXA) * np.exp(-t * 22)


if __name__ == "__main__":
    salvar("magia.wav", magia())
    salvar("sopro.wav", sopro())
    salvar("vento.wav", vento())
    salvar("pop.wav", pop())
