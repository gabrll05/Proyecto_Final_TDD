#define ACK 4
#define SS 2
#define SCK 5
#define MOSI 6
#define REQ 3

#define HANDSHAKE_DATA 0b00011
#define DELAY_MS 30
#define SCK_DELAY_MS 10

bool activeSession = false;
String inputString = "";
bool stringComplete = false;

void IntToBitArray(uint8_t data, uint8_t *bitArray, int size) {
  for (int i = 0; i < size; i++) {
    bitArray[i] = (data >> (size - 1 - i)) & 0x01;
  }
}

void SendByte(uint8_t data, uint8_t size) {
  uint8_t byteToSend[8]; // max 8 bits
  IntToBitArray(data, byteToSend, size);
  for (int i = 0; i < size; i++) {
    digitalWrite(MOSI, byteToSend[i]);
    delay(SCK_DELAY_MS);
    digitalWrite(SCK, 1);
    delay(DELAY_MS);
    digitalWrite(SCK, 0);
    digitalWrite(MOSI, 0);
  }
}

void SendData(uint8_t data, int size) {
  if (activeSession) {
    digitalWrite(SS, 0);
    delay(DELAY_MS);
    SendByte(data, size);
    delay(DELAY_MS);
    digitalWrite(SS, 1);
    Serial.print(F("Datos enviados: 0x"));
    Serial.print(data, HEX);
    Serial.print(F(", tamaño: "));
    Serial.println(size);
  } else {
    digitalWrite(REQ, 0);
    Serial.println(F("No hay una sesión activa."));
  }
}

void EndSession() {
  digitalWrite(SS, 1);
  digitalWrite(SCK, 1);
  digitalWrite(REQ, 0);
  delay(DELAY_MS);
  digitalWrite(SCK, 0);
  activeSession = false;
  Serial.println(F("Comunicaciones cerradas."));
}

void StartSession() {
  digitalWrite(REQ, 1);
  delay(DELAY_MS);
  SendByte(HANDSHAKE_DATA, 5);
  delay(DELAY_MS);
  if (digitalRead(ACK)) {
    activeSession = true;
    Serial.println(F("Handshake exitoso."));
  } else {
    digitalWrite(REQ, 0);
    Serial.println(F("Handshake fallido."));
  }
}

// ----------- NUEVO: procesar expresión tipo "3+5" -----------
// Ahora SOLO envía A y B (NO envía el código de la operación).
// El FPGA hace todas las operaciones con esos dos valores.

void ProcessExpressionCommand(String expr) {
  // quitar espacios
  String clean = "";
  for (unsigned int i = 0; i < expr.length(); i++) {
    char c = expr.charAt(i);
    if (c != ' ' && c != '\t' && c != '\r') {
      clean += c;
    }
  }

  if (clean.length() < 3) {
    Serial.println(F("Error: expresión demasiado corta. Ej: 3+5"));
    return;
  }

  // encontrar operador (solo para validar, ya NO se envía)
  int opPos = clean.indexOf('+');
  if (opPos == -1) opPos = clean.indexOf('-');
  if (opPos == -1) opPos = clean.indexOf('*');
  if (opPos == -1) opPos = clean.indexOf('/');
  if (opPos <= 0 || opPos >= (int)clean.length() - 1) {
    Serial.println(F("Error: formato inválido. Use algo como 3+5"));
    return;
  }

  char aChar = clean.charAt(0);
  char bChar = clean.charAt(opPos + 1);
  char opCh  = clean.charAt(opPos);

  if (aChar < '0' || aChar > '9' || bChar < '0' || bChar > '9') {
    Serial.println(F("Error: solo dígitos 0-9 soportados por ahora."));
    return;
  }

  uint8_t a = (uint8_t)(aChar - '0');
  uint8_t b = (uint8_t)(bChar - '0');

  // Validar operador (pero ya NO generamos opCode ni lo mandamos)
  switch (opCh) {
    case '+':
    case '-':
    case '*':
    case '/':
      // válido, no hacemos nada más
      break;
    default:
      Serial.println(F("Operador inválido (use + - * /)."));
      return;
  }

  if (!activeSession) {
    Serial.println(F("Error: no hay sesión SPI activa. Use 'Start' primero."));
    return;
  }

  // 🔴 AHORA: SOLO mandamos A y B, cada uno como nibble (4 bits)
  SendData(a, 4);
  delay(DELAY_MS);
  SendData(b, 4);

  Serial.print(F("Expresión enviada (solo A y B): "));
  Serial.print(a);
  Serial.print(opCh);
  Serial.println(b);
}

// ----------- comandos seriales clásicos -----------

void ProcessSendCommand(String command) {
  // Eliminar "send;" del inicio
  command = command.substring(5);
  
  // Buscar el segundo separador
  int secondSeparator = command.indexOf(';');
  if (secondSeparator == -1) {
    Serial.println(F("Error: Formato incorrecto. Use: Send;{data[HEX]};{size[int]}"));
    return;
  }
  
  // Extraer data y size
  String dataStr = command.substring(0, secondSeparator);
  String sizeStr = command.substring(secondSeparator + 1);
  
  // Validar y convertir data (HEX)
  dataStr.trim();
  if (dataStr.length() == 0) {
    Serial.println(F("Error: Data no especificada"));
    return;
  }
  
  // Convertir HEX string to uint8_t
  uint8_t data;
  if (dataStr.startsWith("0x")) {
    dataStr = dataStr.substring(2);
  }
  
  char *endptr;
  long dataLong = strtol(dataStr.c_str(), &endptr, 16);
  if (*endptr != '\0' || dataLong < 0 || dataLong > 255) {
    Serial.println(F("Error: Data HEX inválida. Use valores entre 0x00 y 0xFF"));
    return;
  }
  data = (uint8_t)dataLong;
  
  // Validar y convertir size
  sizeStr.trim();
  if (sizeStr.length() == 0) {
    Serial.println(F("Error: Size no especificado"));
    return;
  }
  
  int size = sizeStr.toInt();
  if (size <= 0 || size > 8) {
    Serial.println(F("Error: Size inválido. Use valores entre 1 y 8"));
    return;
  }
  
  // Enviar datos
  SendData(data, size);
}

// ----------- router de comandos -----------

void ProcessSerialCommand(String command) {
  command.trim();
  if (command.length() == 0) return;
  
  command.toLowerCase();  // solo afecta letras, no símbolos

  if (command == "start") {
    Serial.println(F("Iniciando sesión..."));
    StartSession();
    return;
  }
  
  if (command == "end") {
    Serial.println(F("Finalizando sesión..."));
    EndSession();
    return;
  }

  // Si contiene + - * / lo tratamos como expresión tipo "3+5"
  if (command.indexOf('+') != -1 ||
      command.indexOf('-') != -1 ||
      command.indexOf('*') != -1 ||
      command.indexOf('/') != -1) {
    ProcessExpressionCommand(command);
    return;
  }
  
  // Procesar comando Send;data;size
  if (command.startsWith("send;")) {
    ProcessSendCommand(command);
    return;
  }
  
  // Comando no reconocido
  Serial.print(F("Comando no reconocido: "));
  Serial.println(command);
  Serial.println(F("Comandos válidos: Start, End, Send;data;size, o expresiones tipo 3+5"));
}

// ----------- setup / loop -----------

void setup() {
  while (!Serial) { delay(10); }
  Serial.begin(115200);
  
  pinMode(ACK, INPUT);
  pinMode(SS, OUTPUT);
  pinMode(SCK, OUTPUT);
  pinMode(MOSI, OUTPUT);
  pinMode(REQ, OUTPUT);

  digitalWrite(SS, 1);
  
  Serial.println(F("Sistema listo."));
  Serial.println(F("Comandos:"));
  Serial.println(F("  Start              -> Iniciar sesión SPI"));
  Serial.println(F("  End                -> Terminar sesión SPI"));
  Serial.println(F("  Send;0A;4          -> Enviar dato manual (HEX, size bits)"));
  Serial.println(F("  3+5, 7-2, 4*3, 8/2 -> Enviar expresión A op B (solo A y B al FPGA)"));
}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar == '\n') {
      stringComplete = true;
    } else if (inChar != '\r') {
      inputString += inChar;
    }
  }
}

void loop() {
  if (activeSession && !digitalRead(ACK)) {
    activeSession = false;
    Serial.println(F("La sesión ha terminado (ACK = 0)."));
  }
  
  serialEvent();
  if (stringComplete) {
    ProcessSerialCommand(inputString);
    inputString = "";
    stringComplete = false;
  }
}
