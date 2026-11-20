"""Remove o fundo verde (chroma key) de uma imagem e salva PNG com transparência.

Uso (na raiz do projeto):
    python tools/remover_fundo.py entrada.jpeg assets/minotauro/minotauro_frente.png

Opções:
    --baixo N   diferença de verde abaixo da qual o pixel é 100% opaco (padrão 25)
    --alto N    diferença de verde acima da qual o pixel é 100% transparente (padrão 70)
    --altura N  altura final em pixels (padrão: mantém a original recortada)

Requer: pip install pillow numpy
"""
import argparse

import numpy as np
from PIL import Image


def remover_fundo(caminho_in, caminho_out, baixo=25.0, alto=70.0, altura=None):
    img = Image.open(caminho_in).convert("RGB")
    rgb = np.asarray(img).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]

    # Quanto o verde "sobra" em relação ao maior entre vermelho e azul.
    # Fundo verde: valor alto. Bronze, pele e couro: valor baixo ou negativo.
    sobra = g - np.maximum(r, b)
    alfa = np.clip((alto - sobra) / (alto - baixo), 0.0, 1.0)

    # Despill: tira o reflexo verde que fica nas bordas do personagem.
    g_limpo = np.minimum(g, np.maximum(r, b))
    rgb[..., 1] = g_limpo

    # Descarta manchas soltas de alfa quase transparente.
    alfa[alfa < 0.04] = 0.0

    # Recorta pela caixa do personagem (sobras do cenário ficam de fora).
    ys, xs = np.where(alfa > 0.5)
    if len(xs) == 0:
        raise SystemExit("Nada encontrado: ajuste --baixo e --alto.")
    margem = 8
    x0, x1 = max(xs.min() - margem, 0), min(xs.max() + margem + 1, alfa.shape[1])
    y0, y1 = max(ys.min() - margem, 0), min(ys.max() + margem + 1, alfa.shape[0])

    saida = np.dstack([rgb, alfa * 255.0])[y0:y1, x0:x1]
    resultado = Image.fromarray(np.clip(saida, 0, 255).astype(np.uint8), "RGBA")

    if altura:
        proporcao = altura / resultado.height
        resultado = resultado.resize(
            (round(resultado.width * proporcao), altura), Image.LANCZOS
        )

    resultado.save(caminho_out)
    print(f"Salvo: {caminho_out} ({resultado.width}x{resultado.height})")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("entrada")
    p.add_argument("saida")
    p.add_argument("--baixo", type=float, default=25.0)
    p.add_argument("--alto", type=float, default=70.0)
    p.add_argument("--altura", type=int, default=None)
    a = p.parse_args()
    remover_fundo(a.entrada, a.saida, a.baixo, a.alto, a.altura)