# 🌽 FarmTech Solutions — Sistema de Irrigação Inteligente

## 📋 Descrição do Projeto

Sistema de irrigação automatizado e inteligente para lavoura de **milho**, desenvolvido como parte do trabalho da Fase 2 do curso de IA da FIAP. O projeto integra sensores eletrônicos simulados no ESP32 (Wokwi), análise de dados em Python com API climática e análise estatística em R para tomada de decisão sobre irrigação.

---

## 🏗️ Estrutura do Repositório

```
fase2/
├── README.md
├── esp32/
│   ├── src/
│   │   └── main.cpp       # Código principal do ESP32
│   ├── diagram.json       # Diagrama de conexões Wokwi
│   ├── platformio.ini     # Configuração do PlatformIO
│   └── wokwi.toml         # Configuração do simulador Wokwi
├── python/
│   ├── farmtech.py        # Sistema de gestão + API OpenWeather
│   └── dados_plantio.csv  # Dados exportados das culturas
└── r/
    └── irrigacao_analise.R # Análise estatística e decisão de irrigação
```

---

## 🔧 Componentes do Circuito (ESP32 + Wokwi)

| Componente | Função | Pino ESP32 |
|---|---|---|
| Push Button Verde (N) | Simula sensor de Nitrogênio | GPIO 22 |
| Push Button Verde (P) | Simula sensor de Fósforo | GPIO 21 |
| Push Button Verde (K) | Simula sensor de Potássio | GPIO 19 |
| Sensor LDR | Simula pH do solo (0-14) | GPIO 34 |
| Sensor DHT22 | Simula umidade do solo (%) | GPIO 23 |
| Relé Azul | Representa bomba d'água | GPIO 18 |

### Diagrama do Circuito
> Circuito montado e simulado na plataforma Wokwi.com

---

## 🌽 Cultura Escolhida: Milho

### Parâmetros ideais do milho utilizados no sistema:

| Parâmetro | Valor Ideal | Valor Mínimo |
|---|---|---|
| Nitrogênio | 3.0 kg/100m² | 2.0 kg/100m² |
| Fósforo | 2.0 kg/100m² | 1.5 kg/100m² |
| Potássio | 2.0 kg/100m² | 1.0 kg/100m² |
| pH do solo | 5.5 a 7.0 | — |
| Umidade do solo | ≥ 60% | — |

---

## ⚙️ Lógica de Decisão — Quando ligar a bomba?

A bomba d'água (relé) é ativada quando:

1. **Umidade do solo abaixo de 60%** (leitura do DHT22)
2. **Combinada com** pelo menos uma das condições:
   - NPK deficiente (algum botão não pressionado)
   - pH fora da faixa ideal (LDR fora do range)
3. **E não há previsão de chuva moderada ou forte** (API OpenWeather)

A bomba é **suspensa automaticamente** quando `nivelChuva >= 2` (chuva moderada ou forte prevista).

---

## 🐍 Python — Sistema de Gestão (farmtech.py)

Sistema de gerenciamento das culturas com as seguintes funcionalidades:

- **Inserir área** — cadastra dimensões e insumos NPK por cultura
- **Ver dados** — exibe resumo de todas as culturas
- **Atualizar área** — modifica dados cadastrados
- **Deletar área** — remove dados de uma cultura
- **Exportar CSV** — gera arquivo `dados_plantio.csv`
- **Consultar clima** — integração com API OpenWeather para Poços de Caldas/MG

### 🌤️ Integração OpenWeather (Ir Além — Opcional 1)

O sistema consulta a API OpenWeather e retorna:
- Temperatura, umidade e condição atual
- Previsão das próximas 12 horas
- Nível de chuva (0=sem chuva, 1=leve, 2=moderada, 3=forte)
- Recomendação automática de irrigação
- Variável pronta para copiar no código C++ do ESP32

---

## 📊 R — Análise Estatística (Ir Além — Opcional 2)

Script R com análise estatística completa para decisão de irrigação:

### Análises realizadas:
1. **Estatísticas descritivas** — média, mediana e desvio padrão dos insumos
2. **Análise de deficiência NPK** — compara valores cadastrados com parâmetros ideais do milho
3. **Simulação de leituras** — 30 amostras de umidade e pH com distribuição normal
4. **Teste de hipótese (t-test)** — decide estatisticamente se a umidade está abaixo do ideal
   - H0: Umidade ≥ 60% (não precisa irrigar)
   - H1: Umidade < 60% (precisa irrigar)
5. **Análise do pH** — verifica percentual de amostras fora da faixa ideal
6. **Regressão linear** — relação entre nitrogênio e produtividade (sacas/hectare)
7. **Decisão final** — `int ligarBomba = 1` ou `0` para copiar no ESP32

### Gráficos gerados:
- 📊 Barras de insumos totais por cultura
- 📈 Histograma da distribuição de umidade com linha de limite mínimo
- 📉 Regressão linear Nitrogênio vs Produtividade

---

## 🛠️ Ferramentas Utilizadas

- **ESP32** + Wokwi.com (simulador)
- **PlatformIO** + VS Code
- **C++** com framework Arduino
- **Python 3.14** com API OpenWeather
- **R 4.5.3** + RStudio
- **Git** + GitHub

---

## 🎥 Vídeo de Demonstração

> Link do vídeo no YouTube: **[Assistir no YouTube](https://youtu.be/bu4KfaP6pcw?feature=shared)**

---

## 👤 Autor

- **Rafael dos Santos** — RM568949
- Curso: Inteligência Artificial — FIAP
- Turma: 1TIAOA — Fase 2
