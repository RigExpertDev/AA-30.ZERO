// UART bridge for data exchange between 
// RigExpert AA-30 ZERO antenna & cable analyzer and Arduino Uno
//
// Receives from the Arduino, sends to AA-30 ZERO.
// Receives from AA-30 ZERO, sends to the Arduino.
//
// 26 June 2017, Rig Expert Ukraine Ltd.
//
#include <SoftwareSerial.h>

SoftwareSerial ZERO(4, 7);  // RX, TX

void setup() {
  ZERO.begin(38400);        // init AA side UART
  ZERO.flush();
  Serial.begin(38400);      // init PC side UART
  Serial.flush();
}

void loop() {
  if (ZERO.available()) Serial.write(ZERO.read());    // data stream from AA to PC
  if (Serial.available()) ZERO.write(Serial.read());  // data stream from PC to AA
}

