# ============================================================
# Sistema de Irrigação Inteligente - Análise Estatística em R
# Cultura: Milho | Região: Sul de Minas Gerais
# ============================================================

# ========================
# 1. LEITURA DOS DADOS
# ========================
dados <- read.csv("dados_plantio.csv", stringsAsFactors = FALSE)

cat("=== Dados Carregados ===\n")
print(dados)
cat("\n")

# Filtra apenas os dados do milho
milho <- subset(dados, cultura == "milho")

cat("=== Dados do Milho ===\n")
print(milho)
cat("\n")

# ========================
# 2. ESTATÍSTICAS DESCRITIVAS DOS INSUMOS
# ========================
cat("=== Estatisticas Descritivas dos Insumos (Milho) ===\n")
cat(sprintf("Media kg/100m2   : %.2f kg\n", mean(milho$kg_por_100m2)))
cat(sprintf("Mediana kg/100m2 : %.2f kg\n", median(milho$kg_por_100m2)))
cat(sprintf("Desvio Padrao    : %.2f kg\n", sd(milho$kg_por_100m2)))
cat(sprintf("Total de insumos : %.2f kg\n", sum(milho$total_kg)))
cat(sprintf("Area total       : %.2f m2\n", unique(milho$area_m2)))
cat("\n")

# ========================
# 3. PARÂMETROS IDEAIS DO MILHO
# Baseados em referências agronômicas reais
# ========================
npk_ideal <- data.frame(
  insumo         = c("nitrogenio", "fosforo", "potassio"),
  kg_ideal_100m2 = c(3.0, 2.0, 2.0),  # kg por 100m2 recomendado
  kg_minimo_100m2 = c(2.0, 1.5, 1.0)  # mínimo aceitável
)

cat("=== Parametros Ideais para o Milho ===\n")
print(npk_ideal)
cat("\n")

# ========================
# 4. ANÁLISE DE DEFICIÊNCIA NPK
# ========================
cat("=== Analise de Deficiencia NPK ===\n")

necessita_irrigacao_npk <- FALSE

for (i in 1:nrow(npk_ideal)) {
  insumo_nome <- npk_ideal$insumo[i]
  ideal       <- npk_ideal$kg_ideal_100m2[i]
  minimo      <- npk_ideal$kg_minimo_100m2[i]
  
  # Busca o valor atual no CSV
  linha <- subset(milho, insumo == insumo_nome)
  
  if (nrow(linha) > 0) {
    atual <- linha$kg_por_100m2[1]
    deficit <- ideal - atual
    percentual <- (atual / ideal) * 100
    
    status <- ifelse(atual >= ideal, "✅ IDEAL",
                     ifelse(atual >= minimo, "⚠️  ACEITAVEL", "❌ DEFICIENTE"))
    
    cat(sprintf("%-12s | Atual: %.2f kg | Ideal: %.2f kg | %.1f%% | %s\n",
                insumo_nome, atual, ideal, percentual, status))
    
    if (atual < minimo) {
      necessita_irrigacao_npk <- TRUE
    }
  } else {
    cat(sprintf("%-12s | NAO CADASTRADO | ❌ DEFICIENTE\n", insumo_nome))
    necessita_irrigacao_npk <- TRUE
  }
}
cat("\n")

# ========================
# 5. SIMULAÇÃO DE DADOS DE SENSORES
# Como não temos dados históricos reais, simulamos
# leituras baseadas em distribuição normal
# ========================
set.seed(42)  # semente para reprodutibilidade

# Simula 30 leituras de umidade do solo (%)
umidade_simulada <- rnorm(30, mean = 55, sd = 10)
umidade_simulada <- pmax(0, pmin(100, umidade_simulada))  # limita 0-100%

# Simula 30 leituras de pH (escala 0-14)
ph_simulado <- rnorm(30, mean = 6.2, sd = 0.8)
ph_simulado <- pmax(0, pmin(14, ph_simulado))  # limita 0-14

cat("=== Estatisticas das Leituras Simuladas (30 amostras) ===\n")
cat(sprintf("Umidade - Media: %.2f%% | Desvio Padrao: %.2f%%\n",
            mean(umidade_simulada), sd(umidade_simulada)))
cat(sprintf("pH      - Media: %.2f   | Desvio Padrao: %.2f\n",
            mean(ph_simulado), sd(ph_simulado)))
cat("\n")

# ========================
# 6. ANÁLISE ESTATÍSTICA - TESTE DE HIPÓTESE
# H0: umidade >= 60% (não precisa irrigar)
# H1: umidade < 60%  (precisa irrigar)
# ========================
cat("=== Teste de Hipotese - Umidade do Solo ===\n")
cat("H0: Umidade media >= 60% (nao precisa irrigar)\n")
cat("H1: Umidade media < 60%  (precisa irrigar)\n\n")

# Teste t unilateral (menor que)
teste_t <- t.test(umidade_simulada, mu = 60, alternative = "less")

cat(sprintf("Media amostral   : %.2f%%\n", mean(umidade_simulada)))
cat(sprintf("Valor-p          : %.4f\n", teste_t$p.value))
cat(sprintf("Estatistica t    : %.4f\n", teste_t$statistic))
cat(sprintf("Intervalo 95%%    : [%.2f, %.2f]\n",
            teste_t$conf.int[1], teste_t$conf.int[2]))

necessita_irrigacao_umidade <- teste_t$p.value < 0.05

if (necessita_irrigacao_umidade) {
  cat("Resultado: ✅ Rejeita H0 — Umidade ABAIXO do ideal (p < 0.05)\n")
} else {
  cat("Resultado: ❌ Nao rejeita H0 — Umidade dentro do aceitavel\n")
}
cat("\n")

# ========================
# 7. ANÁLISE DO pH
# pH ideal do milho: 5.5 a 7.0
# ========================
cat("=== Analise do pH do Solo ===\n")
ph_medio <- mean(ph_simulado)
ph_ideal_min <- 5.5
ph_ideal_max <- 7.0

amostras_fora_ph <- sum(ph_simulado < ph_ideal_min | ph_simulado > ph_ideal_max)
percentual_fora  <- (amostras_fora_ph / length(ph_simulado)) * 100

cat(sprintf("pH medio         : %.2f\n", ph_medio))
cat(sprintf("Faixa ideal      : %.1f a %.1f\n", ph_ideal_min, ph_ideal_max))
cat(sprintf("Amostras fora    : %d de %d (%.1f%%)\n",
            amostras_fora_ph, length(ph_simulado), percentual_fora))

necessita_correcao_ph <- ph_medio < ph_ideal_min || ph_medio > ph_ideal_max

if (necessita_correcao_ph) {
  cat("Resultado: ⚠️  pH FORA da faixa ideal — correcao necessaria\n")
} else {
  cat("Resultado: ✅ pH dentro da faixa ideal\n")
}
cat("\n")

# ========================
# 8. REGRESSÃO LINEAR
# Relação entre kg de nitrogênio e produtividade estimada
# ========================
cat("=== Regressao Linear - Nitrogenio vs Produtividade ===\n")

# Dados simulados de produtividade (sacas/hectare) vs nitrogenio (kg/100m2)
nitrogenio_hist <- c(1.0, 1.5, 2.0, 2.3, 2.5, 3.0, 3.5, 4.0)
produtividade   <- c(40,  55,  70,  76,  80,  90,  95,  98)

modelo <- lm(produtividade ~ nitrogenio_hist)
resumo <- summary(modelo)

cat(sprintf("Coeficiente angular (inclinacao): %.2f sacas por kg/100m2\n",
            coef(modelo)[2]))
cat(sprintf("Coeficiente linear  (intercepto): %.2f sacas\n",
            coef(modelo)[1]))
cat(sprintf("R² (qualidade do ajuste)         : %.4f\n", resumo$r.squared))

# Predição com o valor atual de nitrogênio
nitrogenio_atual <- subset(milho, insumo == "nitrogenio")$kg_por_100m2[1]
produtividade_prevista <- predict(modelo,
                                  newdata = data.frame(nitrogenio_hist = nitrogenio_atual))

cat(sprintf("\nNitrogenio atual  : %.2f kg/100m2\n", nitrogenio_atual))
cat(sprintf("Produtividade prev: %.1f sacas/hectare\n", produtividade_prevista))
cat("\n")

# ========================
# 9. DECISÃO FINAL — LIGAR OU NÃO A BOMBA
# ========================
cat("============================================\n")
cat("   DECISAO FINAL DO SISTEMA DE IRRIGACAO   \n")
cat("============================================\n")

cat(sprintf("Umidade baixa      : %s\n", ifelse(necessita_irrigacao_umidade, "SIM", "NAO")))
cat(sprintf("NPK deficiente     : %s\n", ifelse(necessita_irrigacao_npk, "SIM", "NAO")))
cat(sprintf("pH fora do ideal   : %s\n", ifelse(necessita_correcao_ph, "SIM", "NAO")))
cat("\n")

# Lógica de decisão
if (necessita_irrigacao_umidade && (necessita_irrigacao_npk || necessita_correcao_ph)) {
  decisao <- "LIGAR"
  motivo  <- "Umidade baixa + problemas de NPK ou pH"
} else if (necessita_irrigacao_umidade) {
  decisao <- "LIGAR"
  motivo  <- "Umidade do solo abaixo do ideal"
} else {
  decisao <- "DESLIGAR"
  motivo  <- "Condicoes dentro do aceitavel"
}

cat(sprintf(">>> BOMBA D'AGUA: %s <<<\n", decisao))
cat(sprintf("Motivo: %s\n", motivo))
cat("============================================\n\n")

# ========================
# 10. VARIÁVEL PARA O ESP32
# ========================
ligar_bomba_esp32 <- ifelse(decisao == "LIGAR", 1, 0)
cat("=== Variavel para copiar no codigo ESP32 ===\n")
cat(sprintf("int ligarBomba = %d;  // 1=LIGAR | 0=DESLIGAR (decisao do R)\n",
            ligar_bomba_esp32))
cat("\n")

# ========================
# 11. GRÁFICOS
# ========================
cat("=== Gerando Graficos ===\n")

# Gráfico 1 - Barras de insumos
barplot(milho$total_kg,
        names.arg = milho$insumo,
        col       = c("#2196F3", "#4CAF50", "#FF9800"),
        main      = "Total de Insumos - Milho (kg)",
        xlab      = "Insumo",
        ylab      = "Total (kg)",
        border    = "white")

# Gráfico 2 - Histograma da umidade simulada
hist(umidade_simulada,
     col    = "#2196F3",
     main   = "Distribuicao da Umidade do Solo (simulada)",
     xlab   = "Umidade (%)",
     ylab   = "Frequencia",
     border = "white")
abline(v = 60, col = "red", lwd = 2, lty = 2)
legend("topright", legend = "Limite minimo (60%)",
       col = "red", lwd = 2, lty = 2)

# Gráfico 3 - Regressão linear
plot(nitrogenio_hist, produtividade,
     main = "Regressao Linear - Nitrogenio vs Produtividade",
     xlab = "Nitrogenio (kg/100m2)",
     ylab = "Produtividade (sacas/hectare)",
     pch  = 19,
     col  = "#4CAF50")
abline(modelo, col = "red", lwd = 2)
points(nitrogenio_atual, produtividade_prevista,
       pch = 17, col = "blue", cex = 2)
legend("topleft",
       legend = c("Dados historicos", "Linha de regressao", "Valor atual"),
       col    = c("#4CAF50", "red", "blue"),
       pch    = c(19, NA, 17),
       lty    = c(NA, 1, NA),
       lwd    = c(NA, 2, NA))

cat("Graficos gerados com sucesso!\n")