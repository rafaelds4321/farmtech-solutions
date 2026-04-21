# Sistema de Gestão de Plantio
# Culturas: Café e Milho
# Integração com API OpenWeather - Poços de Caldas/MG

import csv
import urllib.request
import json

# ========================
# Configuração da API
# ========================
API_KEY = "48c1b0d5d9300191ea17a997aae26950"
CIDADE = "Pocos de Caldas"
URL_CLIMA = f"http://api.openweathermap.org/data/2.5/weather?q=Pocos+de+Caldas,BR&appid={API_KEY}&units=metric&lang=pt_br"
URL_PREVISAO = f"http://api.openweathermap.org/data/2.5/forecast?q=Pocos+de+Caldas,BR&appid={API_KEY}&units=metric&lang=pt_br"

CULTURAS = ["cafe", "milho"]
INSUMOS_DISPONIVEIS = ["potassio", "nitrogenio", "fosforo"]

areas = [0.0, 0.0]
insumos_por_cultura = [[], []]  # lista de dicts {insumo, kg_por_100m2} por cultura

# Variável global de nível de chuva para usar no ESP32
# 0 = sem chuva, 1 = chuva leve, 2 = chuva moderada, 3 = chuva forte
nivel_chuva_esp32 = 0


def formatar_numero(valor):
    """Formata número no padrão brasileiro (ex: 1.234,56)."""
    return f"{valor:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.')


def obter_index_cultura():
    """Exibe menu de culturas e retorna o índice escolhido."""
    print("Qual cultura?")
    print("0 - Cafe")
    print("1 - Milho")
    escolha = input("Opcao: ").strip().lower()
    if escolha in ("0", "cafe"):
        return 0
    elif escolha in ("1", "milho"):
        return 1
    return -1


def obter_dimensoes(prefixo=""):
    """Solicita comprimento e largura e retorna a área calculada."""
    comp = float(input(f"{prefixo}Comprimento em metros: "))
    larg = float(input(f"{prefixo}Largura em metros: "))
    return comp * larg


def selecionar_insumos():
    """Permite ao usuário selecionar múltiplos insumos e suas quantidades."""
    insumos_selecionados = []

    while True:
        print("\nInsumos disponiveis:")
        for i, insumo in enumerate(INSUMOS_DISPONIVEIS):
            print(f"{i} - {insumo}")
        print("S - Finalizar selecao de insumos")

        escolha = input("Escolha um insumo: ").strip().lower()

        if escolha == "s":
            break

        try:
            index = int(escolha)
            if 0 <= index < len(INSUMOS_DISPONIVEIS):
                insumo = INSUMOS_DISPONIVEIS[index]
                kg = float(input(f"Quantidade de {insumo} por 100m2 (kg): "))
                insumos_selecionados.append({"insumo": insumo, "kg_por_100m2": kg})
                print(f"{insumo} adicionado!")
            else:
                print("Opcao invalida.")
        except ValueError:
            print("Digite um numero valido.")

    return insumos_selecionados


def inserir_area():
    """Insere a área e os insumos de uma cultura."""
    index = obter_index_cultura()
    if index in (0, 1):
        areas[index] = obter_dimensoes()
        print(f"Area de {CULTURAS[index]} calculada: {formatar_numero(areas[index])} m2")
        insumos_por_cultura[index] = selecionar_insumos()
    else:
        print("Opcao invalida.")


def ver_dados():
    """Exibe os dados de todas as culturas."""
    print()
    for i in range(len(CULTURAS)):
        print(f"Cultura : {CULTURAS[i]}")
        print(f"Area    : {formatar_numero(areas[i])} m2")

        if insumos_por_cultura[i]:
            print("Insumos:")
            for item in insumos_por_cultura[i]:
                total_kg = (areas[i] / 100) * item["kg_por_100m2"]
                print(f"  - {item['insumo']}: {formatar_numero(item['kg_por_100m2'])} kg/100m2 "
                      f"-> Total: {formatar_numero(total_kg)} kg")
        else:
            print("Insumos: nenhum cadastrado")
        print()


def atualizar_area():
    """Atualiza a área e os insumos de uma cultura existente."""
    index = obter_index_cultura()
    if index in (0, 1):
        areas[index] = obter_dimensoes("Novo ")
        print(f"Atualizado! Nova area: {formatar_numero(areas[index])} m2")
        print("Deseja atualizar os insumos tambem? (s/n)")
        if input("Opcao: ").strip().lower() == "s":
            insumos_por_cultura[index] = selecionar_insumos()
    else:
        print("Opcao invalida.")


def deletar_area():
    """Deleta os dados de uma cultura."""
    index = obter_index_cultura()
    if index in (0, 1):
        areas[index] = 0.0
        insumos_por_cultura[index] = []
        print(f"Dados de {CULTURAS[index]} deletados com sucesso!")
    else:
        print("Opcao invalida.")


def exportar_csv():
    """Exporta os dados das culturas e insumos para um arquivo CSV."""
    nome_arquivo = "dados_plantio.csv"
    with open(nome_arquivo, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["cultura", "area_m2", "insumo", "kg_por_100m2", "total_kg"])

        for i in range(len(CULTURAS)):
            if insumos_por_cultura[i]:
                for item in insumos_por_cultura[i]:
                    total_kg = (areas[i] / 100) * item["kg_por_100m2"]
                    writer.writerow([
                        CULTURAS[i],
                        round(areas[i], 2),
                        item["insumo"],
                        round(item["kg_por_100m2"], 2),
                        round(total_kg, 2)
                    ])
            else:
                writer.writerow([CULTURAS[i], round(areas[i], 2), "nenhum", 0, 0])

    print(f"Dados exportados com sucesso para '{nome_arquivo}'!")


def calcular_nivel_chuva(descricao, volume_chuva):
    """
    Calcula o nível de chuva baseado na descrição e volume.
    Retorna:
      0 = sem chuva
      1 = chuva leve (< 2.5mm)
      2 = chuva moderada (2.5mm a 10mm)
      3 = chuva forte (> 10mm)
    """
    descricao = descricao.lower()
    if volume_chuva == 0 and "chuva" not in descricao and "rain" not in descricao:
        return 0
    elif volume_chuva < 2.5:
        return 1
    elif volume_chuva < 10:
        return 2
    else:
        return 3


def recomendar_irrigacao(nivel_chuva):
    """Retorna recomendação de irrigação baseada no nível de chuva."""
    if nivel_chuva == 0:
        return "✅ SEM CHUVA PREVISTA — Irrigacao recomendada conforme sensores"
    elif nivel_chuva == 1:
        return "⚠️  CHUVA LEVE PREVISTA — Irrigacao pode ser reduzida"
    elif nivel_chuva == 2:
        return "🌧️  CHUVA MODERADA PREVISTA — Suspender irrigacao"
    else:
        return "⛈️  CHUVA FORTE PREVISTA — Suspender irrigacao imediatamente"


def consultar_clima():
    """Consulta a API OpenWeather e exibe dados climáticos de Poços de Caldas."""
    global nivel_chuva_esp32

    print("\n=== Consulta Climatica - Pocas de Caldas/MG ===")
    print("Consultando API OpenWeather...")

    try:
        # Clima atual
        with urllib.request.urlopen(URL_CLIMA, timeout=10) as response:
            dados = json.loads(response.read().decode())

        temperatura    = dados["main"]["temp"]
        umidade        = dados["main"]["humidity"]
        descricao      = dados["weather"][0]["description"]
        vento          = dados["wind"]["speed"]
        volume_chuva   = dados.get("rain", {}).get("1h", 0.0)

        print(f"\n📍 Cidade       : {CIDADE}, {dados['sys']['country']}")
        print(f"🌡️  Temperatura  : {temperatura:.1f} °C")
        print(f"💧 Umidade      : {umidade} %")
        print(f"🌤️  Condicao     : {descricao.capitalize()}")
        print(f"💨 Vento        : {vento:.1f} m/s")
        print(f"🌧️  Chuva (1h)   : {volume_chuva:.1f} mm")

        # Previsão das próximas horas
        print("\n--- Previsao proximas horas ---")
        try:
            with urllib.request.urlopen(URL_PREVISAO, timeout=10) as response:
                previsao = json.loads(response.read().decode())

            chuva_prevista = False
            volume_previsto = 0.0

            for item in previsao["list"][:4]:  # próximas 12 horas (4 intervalos de 3h)
                horario = item["dt_txt"]
                desc    = item["weather"][0]["description"]
                temp    = item["main"]["temp"]
                chuva   = item.get("rain", {}).get("3h", 0.0)
                if chuva > 0:
                    chuva_prevista = True
                    volume_previsto += chuva
                print(f"  {horario} | {desc.capitalize()} | {temp:.1f}°C | Chuva: {chuva:.1f}mm")

            # Calcula nível de chuva considerando atual + previsão
            volume_total = volume_chuva + volume_previsto
            nivel_chuva_esp32 = calcular_nivel_chuva(descricao, volume_total)

        except Exception:
            nivel_chuva_esp32 = calcular_nivel_chuva(descricao, volume_chuva)

        # Recomendação
        print(f"\n{'='*50}")
        print(recomendar_irrigacao(nivel_chuva_esp32))
        print(f"{'='*50}")

        # Instrução para o ESP32
        print(f"\n🔧 VARIAVEL PARA O ESP32:")
        print(f"   int nivelChuva = {nivel_chuva_esp32};")
        print(f"   // 0=sem chuva | 1=leve | 2=moderada | 3=forte")
        print(f"\n   Copie o valor acima para o codigo C++ no Wokwi!")

    except urllib.error.URLError as e:
        print(f"\n❌ Erro ao conectar na API: {e}")
        print("Verifique sua chave API e conexao com a internet.")
    except KeyError as e:
        print(f"\n❌ Erro ao processar dados da API: {e}")
        print("Verifique se a chave API esta correta.")


def exibir_menu():
    """Exibe o menu principal."""
    print("\n=== Sistema de Plantio ===")
    print("1 - Inserir area")
    print("2 - Ver dados")
    print("3 - Atualizar area")
    print("4 - Deletar area")
    print("5 - Exportar dados para CSV")
    print("6 - Consultar clima (OpenWeather)")
    print("7 - Sair")
    print()


def main():
    opcao = 0
    acoes = {
        1: inserir_area,
        2: ver_dados,
        3: atualizar_area,
        4: deletar_area,
        5: exportar_csv,
        6: consultar_clima,
    }

    while opcao != 7:
        exibir_menu()
        try:
            opcao = int(input("Opcao: "))
        except ValueError:
            print("Digite um numero valido.")
            continue

        if opcao in acoes:
            acoes[opcao]()
        elif opcao == 7:
            print("Saindo...")
        else:
            print("Opcao invalida.")


if __name__ == "__main__":
    main()