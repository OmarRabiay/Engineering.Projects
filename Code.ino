#include <LiquidCrystal.h>

const int rs = 12, en = 11, d4 = 5, d5 = 4, d6 = 3, d7 = 2;
LiquidCrystal lcd(rs, en, d4, d5, d6, d7);

int n = 0; //Variable for switching modes

//Pins
const int VoltmeterPin = A0;
const int AmmeterPin = A5;
const int OhmmeterPin = A3;
const int DiodePin = A4;
const int ButtonPin = 7; 
const int BuzzerPin = 13; 

//Resistors
const float R1 = 101;
const float R2 = 900;
const float R1Ohm = 4.6;
const float shunt = 10;


void setup() {
  
  lcd.begin(16, 2);
  
  lcd.setCursor(2, 0);
  lcd.print("Measurements");
  lcd.setCursor(4, 1);
  lcd.print("Project");
  delay(20000);
  lcd.clear();
  
  pinMode(VoltmeterPin, INPUT);
  pinMode(AmmeterPin, INPUT);
  pinMode(OhmmeterPin, INPUT);
  pinMode(ButtonPin,INPUT);
  pinMode(BuzzerPin, OUTPUT);

  Serial.begin(9600);
}

void loop() {

  if (digitalRead(7) == HIGH){
    n++;
    delay(300);
  }

  if (n%4== 0){ //Voltmeter
    int V0read = analogRead(VoltmeterPin);
    
    float voltage0 = V0read * (5.0 / 1023.0);
    float voltage = (voltage0 - 2.526882)*((R1+R2)/R1);

    if (abs(voltage) < 0.05)
    {
    voltage = 0.0;
    }

    lcd.clear();
    lcd.print("Voltage: ");
    lcd.setCursor(0, 1);
    lcd.print(voltage,2);
    lcd.print(" V");
    Serial.print("V0: ");
    Serial.println(voltage0,6);
  }

  

  else if (n%4 == 1){ //Ammeter
    int V1read = analogRead(AmmeterPin);
    float voltage1 = V1read * (5.0 / 1023.0);
    float current = ((voltage1 - 2.575757) / shunt) * 1000;

    if (abs(current) < 0.5) {
      current = 0.0;
    }

    lcd.clear();
    lcd.print("Current: ");
    lcd.setCursor(0, 1);
    lcd.print(current,2);
    lcd.print(" mA");
    Serial.print("V1: ");
    Serial.println(voltage1,6);
  }

  else if (n%4 == 2){ //Ohmmeter
    int V2read = analogRead(OhmmeterPin);
    float voltage2 = V2read * (5.0 / 1023.0);
    float R = voltage2 / ((5 - voltage2) / R1Ohm);
    if (R<50){
      lcd.clear();
      lcd.print("Resistance: ");
      lcd.setCursor(0, 1);
      lcd.print(R,2); 
      lcd.print(" KOhm");
    }
    else {
      lcd.clear();
      lcd.print("Resistance: ");
      lcd.setCursor(0, 1);
      lcd.print("Open Circuit");
    }

    Serial.print("V2: ");
    Serial.print(voltage2,6);
    Serial.println(" v");
  }

  else if (n%4 == 3){ // Diode / Continuity

   int V3read = analogRead(DiodePin);
    float voltage3 = V3read * (5.0 / 1023.0);
    if(voltage3>0.05 && voltage3<4){
      lcd.clear();
      lcd.print("Diode: ");
      lcd.setCursor(0,1);
      lcd.print(voltage3);
      lcd.print("V");
    }
    else if (voltage3>4){
      lcd.clear();
      lcd.print("Diode: ");
      lcd.setCursor(0,1);
      lcd.print("Open Circuit");
    }
    else {
      lcd.clear();
      lcd.print("Continuity:");
      lcd.setCursor(1,1);
      lcd.print("True");
      digitalWrite(BuzzerPin,HIGH);
      delay(200);
      digitalWrite(BuzzerPin,LOW); 
    }
    Serial.print("V3: ");
    Serial.print(voltage3,6);
    Serial.println(" v");
  }
  delay(100);
}