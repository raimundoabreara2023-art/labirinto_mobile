"""
Processa quadros individuais de animação do Minotauro.

O script:
  1. remove um fundo de cor uniforme (verde por padrão);
  2. recorta a área visível do personagem;
  3. redimensiona todos os quadros para a mesma altura;
  4. centraliza e alinha os pés na mesma linha de base;
  5. salva PNGs RGBA com transparência.

IMPORTANTE:
  - Cada arquivo de entrada deve conter APENAS UM quadro/personagem.
  - Este script NÃO separa automaticamente uma prancha com vários personagens.
  - Para melhores resultados, gere os quadros com fundo verde puro (#00FF00).

Requer:
    pip install pillow numpy

Exemplo (na raiz do projeto):
    python tools/processar_frames.py --saida assets/minotauro/andando \
        --prefixo minotauro_andando_ \
        originais/andando_1.png originais/andando_2.png \
        originais/andando_3.png originais/andando_4.png

Imagem individual:
    python tools/processar_frames.py --saida assets/minotauro \
        --nome minotauro_rugido.png originais/rugido.png

Fundo personalizado:
    python tools/processar_frames.py --cor-chave "#00FF00" \
        --tolerancia 55 --suavidade 45 --saida assets/minotauro/andando \
        originais/passo1.png originais/passo2.png
"""

import argparse
import os
import re

import numpy as np
from PIL import Image


def converter_cor_hex(valor):
    """Converte '#RRGGBB' em uma tupla RGB."""
    texto = valor.strip().lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", texto):
        raise argparse.ArgumentTypeError(
            "A cor deve estar no formato #RRGGBB, por exemplo #00FF00."
        )
    return tuple(int(texto[i:i + 2], 16) for i in (0, 2, 4))


def recortar(
    caminho,
    cor_chave=(0, 255, 0),
    tolerancia=55.0,
    suavidade=45.0,
    margem=8,
    despill_verde=True,
):
    """
    Remove a cor de fundo e devolve (imagem RGBA recortada, centro x).

    A distância RGB permite usar outras cores uniformes além do verde.
    Tolerância maior remove mais tons próximos da cor-chave.
    Suavidade controla a transição antisserrilhada nas bordas.
    """
    imagem = Image.open(caminho).convert("RGB")
    rgb = np.asarray(imagem).astype(np.float32)

    chave = np.asarray(cor_chave, dtype=np.float32)
    distancia = np.sqrt(np.sum((rgb - chave) ** 2, axis=2))

    suavidade = max(float(suavidade), 1.0)
    alfa = np.clip((distancia - tolerancia) / suavidade, 0.0, 1.0)

    # Remove o reflexo verde nas bordas sem alterar os pixels totalmente opacos.
    if despill_verde and cor_chave[1] > cor_chave[0] * 1.25 and cor_chave[1] > cor_chave[2] * 1.25:
        verde_limpo = np.minimum(rgb[..., 1], np.maximum(rgb[..., 0], rgb[..., 2]))
        peso = 1.0 - alfa
        rgb[..., 1] = rgb[..., 1] * (1.0 - peso) + verde_limpo * peso

    alfa[alfa < 0.025] = 0.0

    ys, xs = np.where(alfa > 0.5)
    if len(xs) == 0:
        raise SystemExit(
            f"Nenhum personagem detectado em '{caminho}'. "
            "Confira a cor do fundo ou ajuste --tolerancia e --suavidade."
        )

    x0 = max(int(xs.min()) - margem, 0)
    x1 = min(int(xs.max()) + margem + 1, rgb.shape[1])
    y0 = max(int(ys.min()) - margem, 0)
    y1 = min(int(ys.max()) + margem + 1, rgb.shape[0])

    recorte = np.dstack((rgb, alfa * 255.0))[y0:y1, x0:x1]
    resultado = Image.fromarray(
        np.clip(recorte, 0, 255).astype(np.uint8),
        mode="RGBA",
    )

    # Centro de massa horizontal do recorte, usado para alinhar os quadros.
    massa = alfa[y0:y1, x0:x1]
    colunas = massa.sum(axis=0)
    soma = float(colunas.sum())
    centro_x = (
        float((colunas * np.arange(colunas.size)).sum() / soma)
        if soma > 0
        else resultado.width / 2
    )

    return resultado, centro_x


def main():
    parser = argparse.ArgumentParser(
        description="Remove o fundo e padroniza quadros individuais do Minotauro."
    )
    parser.add_argument(
        "entradas",
        nargs="+",
        help="Imagens individuais, na ordem correta da animação.",
    )
    parser.add_argument("--saida", required=True, help="Pasta de destino.")
    parser.add_argument(
        "--prefixo",
        default="minotauro_quadro_",
        help="Prefixo dos arquivos numerados.",
    )
    parser.add_argument(
        "--nome",
        help="Nome fixo para processar uma única imagem.",
    )
    parser.add_argument(
        "--altura",
        type=int,
        default=1024,
        help="Altura final dos quadros em pixels (padrão: 1024).",
    )
    parser.add_argument(
        "--cor-chave",
        type=converter_cor_hex,
        default=(0, 255, 0),
        help="Cor do fundo em hexadecimal (padrão: #00FF00).",
    )
    parser.add_argument(
        "--tolerancia",
        type=float,
        default=55.0,
        help="Tolerância da remoção da cor de fundo (padrão: 55).",
    )
    parser.add_argument(
        "--suavidade",
        type=float,
        default=45.0,
        help="Suavidade das bordas (padrão: 45).",
    )
    parser.add_argument(
        "--margem",
        type=int,
        default=8,
        help="Margem transparente ao redor do personagem (padrão: 8).",
    )
    parser.add_argument(
        "--sem-despill",
        action="store_true",
        help="Desativa a correção de reflexo verde nas bordas.",
    )

    args = parser.parse_args()

    if args.nome and len(args.entradas) != 1:
        parser.error("--nome só pode ser usado com uma única imagem.")
    if args.altura < 1:
        parser.error("--altura precisa ser maior que zero.")
    if args.margem < 0:
        parser.error("--margem não pode ser negativa.")

    os.makedirs(args.saida, exist_ok=True)

    quadros = []
    for caminho in args.entradas:
        if not os.path.isfile(caminho):
            parser.error(f"Arquivo não encontrado: {caminho}")

        imagem, centro_x = recortar(
            caminho,
            cor_chave=args.cor_chave,
            tolerancia=args.tolerancia,
            suavidade=args.suavidade,
            margem=args.margem,
            despill_verde=not args.sem_despill,
        )

        escala = args.altura / imagem.height
        nova_largura = max(1, round(imagem.width * escala))
        redimensionada = imagem.resize(
            (nova_largura, args.altura),
            Image.Resampling.LANCZOS,
        )
        quadros.append((redimensionada, centro_x * escala, caminho))

    # Uma largura comum evita que o personagem "salte" lateralmente.
    meia_largura = max(
        max(centro_x, imagem.width - centro_x)
        for imagem, centro_x, _ in quadros
    )
    largura_final = max(1, int(np.ceil(meia_largura * 2)) + 2)

    for indice, (imagem, centro_x, origem) in enumerate(quadros, start=1):
        tela = Image.new(
            "RGBA",
            (largura_final, args.altura),
            (0, 0, 0, 0),
        )

        pos_x = int(round(largura_final / 2 - centro_x))
        # A base de todos os quadros coincide com a base da tela.
        tela.alpha_composite(imagem, (pos_x, 0))

        nome = args.nome or f"{args.prefixo}{indice}.png"
        destino = os.path.join(args.saida, nome)
        tela.save(destino, format="PNG")

        print(
            f"Salvo: {destino} | {tela.width}x{tela.height} "
            f"| origem: {origem}"
        )


if __name__ == "__main__":
    main()
