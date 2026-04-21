#include <Arduino.h>
#include <DHT.h>

// ========================
// Definição dos pinos
// ========================
#define PIN_BTN_N    22   // Botão Nitrogênio
#define PIN_BTN_P    21   // Botão Fósforo
#define PIN_BTN_K    19   // Botão Potássio
#define PIN_LDR      34   // Sensor LDR (pH simulado)
#define PIN_DHT      23   // Sensor DHT22 (umidade simulada)
#define PIN_RELE     18   // Relé (bomba d'água)

#define DHTTYPE DHT22

DHT dht(PIN_DHT, DHTTYPE);

// ========================
// Parâmetros do Milho
// ========================
// pH ideal do milho: 5.5 a 7.0
// Simulamos o LDR com leitura de 0 a 4095 (ADC 12 bits do ESP32)
// Mapeamos para escala de pH 0 a 14
// pH ideal = leitura entre 1607 e 2047 (aprox.)
#define PH_MIN        1607   // equivale a pH 5.5
#define PH_MAX        2047   // equivale a pH 7.0

// Umidade mínima do solo para o milho (%)
// Abaixo de 60% -> precisa irrigar
#define UMIDADE_MIN   60.0

// ========================
// Integração com OpenWeather (via Python)
// Copie o valor gerado pelo Python aqui:
// 0 = sem chuva
// 1 = chuva leve
// 2 = chuva moderada
// 3 = chuva forte
// ========================
int nivelChuva = 0;  // << ATUALIZE COM O VALOR DO PYTHON

void setup() {
  Serial.begin(115200);

  // Configura botões com pull-up interno
  pinMode(PIN_BTN_N, INPUT_PULLUP);
  pinMode(PIN_BTN_P, INPUT_PULLUP);
  pinMode(PIN_BTN_K, INPUT_PULLUP);

  // Configura LDR como entrada analógica
  pinMode(PIN_LDR, INPUT);

  // Configura relé como saída e começa desligado
  pinMode(PIN_RELE, OUTPUT);
  digitalWrite(PIN_RELE, LOW);

  dht.begin();

  Serial.println("=================================");
  Serial.println(" Sistema de Irrigação - Milho   ");
  Serial.println("=================================");
}

void loop() {

  // ========================
  // Leitura dos botões NPK
  // LOW = pressionado = nutriente presente
  // HIGH = não pressionado = nutriente ausente
  // ========================
  bool nitrogenio  = (digitalRead(PIN_BTN_N) == LOW);
  bool fosforo     = (digitalRead(PIN_BTN_P) == LOW);
  bool potassio    = (digitalRead(PIN_BTN_K) == LOW);

  // ========================
  // Leitura do LDR (pH simulado)
  // ========================
  int ldrValor = analogRead(PIN_LDR);
  // Mapeia leitura do LDR (0-4095) para pH (0-14)
  float ph = map(ldrValor, 0, 4095, 0, 140) / 10.0;
  bool phIdeal = (ldrValor >= PH_MIN && ldrValor <= PH_MAX);

  // ========================
  // Leitura do DHT22 (umidade simulada do solo)
  // ========================
  float umidade     = dht.readHumidity();
  float temperatura = dht.readTemperature();

  // Verifica se a leitura do DHT22 falhou
  if (isnan(umidade) || isnan(temperatura)) {
    Serial.println("[ERRO] Falha ao ler o sensor DHT22!");
    delay(2000);
    return;
  }

  bool precisaIrrigar = false;
  String motivo = "";

  // ========================
  // Lógica de irrigação do Milho
  // A bomba liga se:
  // 1. Umidade abaixo de 60% (solo seco)
  // 2. E pelo menos um nutriente NPK ausente
  // 3. E pH fora da faixa ideal (5.5 a 7.0)
  // 4. E NÃO há previsão de chuva moderada ou forte (OpenWeather)
  // ========================
  bool npkDeficiente  = (!nitrogenio || !fosforo || !potassio);
  bool chuvaForte     = (nivelChuva >= 2);  // suspende irrigação se chuva >= moderada

  if (chuvaForte) {
    precisaIrrigar = false;
    motivo = "Chuva prevista - irrigacao suspensa";
  }
  else if (umidade < UMIDADE_MIN && npkDeficiente && !phIdeal) {
    precisaIrrigar = true;
    motivo = "Umidade baixa + NPK deficiente + pH fora do ideal";
  }
  else if (umidade < UMIDADE_MIN && npkDeficiente) {
    precisaIrrigar = true;
    motivo = "Umidade baixa + NPK deficiente";
  }
  else if (umidade < UMIDADE_MIN && !phIdeal) {
    precisaIrrigar = true;
    motivo = "Umidade baixa + pH fora do ideal";
  }
  else if (umidade < UMIDADE_MIN) {
    precisaIrrigar = true;
    motivo = "Umidade baixa";
  }

  // ========================
  // Aciona ou desliga o relé
  // ========================
  if (precisaIrrigar) {
    digitalWrite(PIN_RELE, HIGH);
  } else {
    digitalWrite(PIN_RELE, LOW);
  }

  // ========================
  // Monitor Serial
  // ========================
  Serial.println("---------------------------------");
  Serial.print("Nitrogenio (N):  ");
  Serial.println(nitrogenio  ? "PRESENTE" : "AUSENTE");
  Serial.print("Fosforo    (P):  ");
  Serial.println(fosforo     ? "PRESENTE" : "AUSENTE");
  Serial.print("Potassio   (K):  ");
  Serial.println(potassio    ? "PRESENTE" : "AUSENTE");
  Serial.print("LDR (raw):       ");
  Serial.println(ldrValor);
  Serial.print("pH simulado:     ");
  Serial.println(ph);
  Serial.print("pH ideal:        ");
  Serial.println(phIdeal ? "SIM (5.5 a 7.0)" : "NAO (fora da faixa)");
  Serial.print("Umidade solo:    ");
  Serial.print(umidade);
  Serial.println(" %");
  Serial.print("Temperatura:     ");
  Serial.print(temperatura);
  Serial.println(" C");
  Serial.print("Nivel chuva:     ");
  Serial.print(nivelChuva);
  Serial.println(" (0=sem|1=leve|2=mod|3=forte)");
  Serial.print("Bomba d'agua:    ");
  Serial.println(precisaIrrigar ? "LIGADA" : "DESLIGADA");
  if (precisaIrrigar || chuvaForte) {
    Serial.print("Motivo:          ");
    Serial.println(motivo);
  }
  Serial.println("---------------------------------");

  delay(2000);
}
