import os
from PIL import Image

def recortar_prancha_precisa(caminho_prancha, pasta_saida="assets/minotauro_sprites"):
    os.makedirs(pasta_saida, exist_ok=True)
    img = Image.open(caminho_prancha).convert("RGB")
    w, h = img.size

    # Verificamos qual prancha é para aplicar o layout de grade correto
    nome_arquivo = os.path.basename(caminho_prancha)

    if "parado" in nome_arquivo or "7" in nome_arquivo:
        # Prancha 1: 2 linhas (Linha superior: 4 andando | Linha inferior: Parado, Ataque, Rugido)
        # Definimos as coordenadas exatas (proporções calculadas da grade)
        sub_quadros = [
            ("minotauro_andando_1.png", (int(w * 0.03), int(h * 0.05), int(w * 0.23), int(h * 0.43))),
            ("minotauro_andando_2.png", (int(w * 0.28), int(h * 0.05), int(w * 0.48), int(h * 0.43))),
            ("minotauro_andando_3.png", (int(w * 0.53), int(h * 0.05), int(w * 0.73), int(h * 0.43))),
            ("minotauro_andando_4.png", (int(w * 0.78), int(h * 0.05), int(w * 0.98), int(h * 0.43))),
            ("minotauro_parado.png",    (int(w * 0.05), int(h * 0.51), int(w * 0.25), int(h * 0.95))),
            ("minotauro_ataque.png",    (int(w * 0.36), int(h * 0.47), int(w * 0.61), int(h * 0.95))),
            ("minotauro_rugido.png",    (int(w * 0.72), int(h * 0.51), int(w * 0.95), int(h * 0.95))),
        ]
    else:
        # Prancha 2 (Rugido/Completa): 3 linhas de quadros
        # Vamos tratar de forma genérica baseada em linhas e colunas se necessário, 
        # ou focar nos recortes exatos da prancha atual.
        sub_quadros = []

    # 1. Realizar os recortes limpos
    recortes_isolados = []
    max_w, max_h = 0, 0

    for nome_sprite, box in sub_quadros:
        quadro = img.crop(box)
        if quadro.width > max_w: max_w = quadro.width
        if quadro.height > max_h: max_h = quadro.height
        recortes_isolados.append((nome_sprite, quadro))

    # 2. Padronizar o tamanho de enquadramento (Requisito 7)
    target_w = int(max_w * 1.1)
    target_h = int(max_h * 1.1)

    for nome_sprite, quadro in recortes_isolados:
        # Criar fundo verde puro e uniforme #00FF00
        canvas = Image.new("RGB", (target_w, target_h), (0, 255, 0))
        
        # Centralizar o personagem isolado na tela verde
        offset_x = (target_w - quadro.width) // 2
        offset_y = (target_h - quadro.height) // 2
        canvas.paste(quadro, (offset_x, offset_y))

        caminho_destino = os.path.join(pasta_saida, nome_sprite)
        canvas.save(caminho_destino, "PNG")
        print(f"Salvo com sucesso e isolado: {caminho_destino} [{target_w}x{target_h}]")

if __name__ == "__main__":
    pranchas = [
        "assets/minotauro/minotauro_parado.png",
        # "assets/minotauro/minotauro_rugido.png" # Adicione a outra se desejar
    ]
    
    for prancha in pranchas:
        if os.path.exists(prancha):
            print(f"\nProcessando prancha: {prancha}")
            recortar_prancha_precisa(prancha)
        else:
            print(f"Arquivo não encontrado: {prancha}")
            
    print("\nProcessamento concluído sem misturar quadros!")