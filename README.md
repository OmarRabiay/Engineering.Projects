# Measurements Project: Multimeter Design

## Device Functions
- Voltage measurement
- Current measurement
- Resistance measurement
- Continuity check
- Diode test

## 🧑‍💻 Team Members
- Omar Islam 
- Shaden Islam 
- Rawan Magdy

**Department**: Electronics & Communication Engineering

## Introduction
In this project, a multifunctional digital multimeter was designed and implemented using Arduino. The device is capable of measuring voltage, current, resistance, as well as testing continuity and diodes. The main objective of this project was to understand and apply electrical measurement concepts practically, by designing circuits for each measurement mode and interpreting their outputs using analog readings. This project allowed us to gain hands-on experience with Arduino programming and circuit design, while also developing skills in circuit analysis and signal processing.

## System Overview
This project involves the design and implementation of a digital multimeter using an Arduino microcontroller. The device is capable of measuring four different electrical quantities: voltage, current, resistance, and diode/continuity testing. Each mode is selected sequentially using a push-button interface, and the corresponding measurement is displayed on an LCD screen.

The system utilizes analog voltage readings obtained through voltage divider and other circuit configurations to compute the target electrical quantity. These readings are processed in software and calibrated to enhance accuracy, then displayed clearly to the user.

## Hardware Implementation

### Components Used:
- **Arduino Uno Microcontroller**: The central unit that controls the system.
- **LCD Screen (16x2)**: Displays measurement results.
- **Breadboard**: Platform for assembling the circuit.
- **Jumper wires**: Used to make connections in the circuit.
- **Resistors**: 5*100 kΩ, 900 kΩ, 3*10 kΩ, 4.7 kΩ, 220Ω.
- **Potentiometer**: Adjusts contrast of the LCD screen.
- **Push Button**: Used to switch between measurement modes.
- **Buzzer**: Gives audible alert for continuity check.

### Simulation: 
#### Method of Implementation:

1. **LCD Display Connection**:
   - LCD RS pin to digital pin 12.
   - LCD Enable pin to digital pin 11.
   - LCD D4 pin to digital pin 5.
   - LCD D5 pin to digital pin 4.
   - LCD D6 pin to digital pin 3.
   - LCD D7 pin to digital pin 2.
   - LCD R/W pin to GND.
   - LCD VSS pin to GND.
   - LCD VCC pin to 5V.
   - LCD LED+ to 5V through a 220-ohm resistor.
   - LCD LED- to GND.
   - Potentiometer wired to +5V and GND, with its wiper (o/p) to LCD screen's VO pin (pin3).

2. **Voltmeter**:
   - **Purpose**: To measure the voltage applied across a component or circuit.
   - **Implementation**:
     - The voltage to be measured is connected to analog pin A0.
     - A voltage divider (R1 = 100 kΩ , R2 = 900 kΩ) scales down the input voltage to fit the Arduino’s range (0-5V).
     - To allow for both positive and negative voltages, the input signal is voltage-shifted by adding a reference voltage (nearly 2.5V) using two equivalent resistors (100kΩ) before it enters the analog pin.
     - The offset is subtracted in the code to get the real voltage:
       ```cpp
       float voltage = (voltage0 - 2.5) * ((R1 + R2) / R1);
       ```
   - **Display**: The voltage value is shown on the LCD with two decimal places. Small readings (< 0.05V) are considered zero to avoid noise.

3. **Ammeter**:
   - **Purpose**: To measure the current passing through a load.
   - **Implementation**:
     - The load is connected in series with a shunt resistor (10Ω).
     - The voltage drop across the shunt is measured using analog pin A5.
     - An offset voltage (nearly 2.5V) is added to the signal using two equivalent resistors (100 Ω). The offset is subtracted in the code:
       ```cpp
       float current = ((voltage1 - 2.5) / shunt) * 1000;
       ```
   - **Display**: The current value is shown on the LCD with two decimal places. If the current is below 0.5 mA, it is treated as zero.

4. **Ohmmeter**:
   - **Purpose**: To measure the resistance of an unknown resistor.
   - **Implementation**:
     - The unknown resistor is placed in a voltage divider circuit with a known resistor (4.7kΩ).
     - The divided voltage is measured at analog pin A3.
     - The unknown resistance is calculated using the voltage divider formula:
       ```cpp
       float R = voltage2 / ((5 - voltage2) / R1Ohm);
       ```
   - **Display**: Shows the resistance in kΩ on the LCD. If the resistance is very high (open circuit), a warning message is displayed.

5. **Diode & Continuity Tester**:
   - **Purpose**: To test whether a diode is functioning or if two points are electrically connected (continuity).
   - **Implementation**:
     - The diode or wire is connected between a voltage source and a resistor (10 kΩ). The voltage is measured at analog pin A4.
     - Based on the voltage:
       - 0.05 < Voltage < 4V (Diode conducting)
       - Voltage > 4V (open circuit)
       - Voltage < 0.05V (Electrical continuity detected)
     - If continuity is detected, a buzzer connected to pin 13 is activated.
   - **Display**: Displays “Diode: X.XV”, “Open Circuit”, or “Continuity: True” on the LCD based on the condition.

6. **Mode Switching**:
   - A push button connected to digital pin 7 switches between the 4 modes (Voltage, Current, Resistance, Diode/Continuity). Each press increments a counter `n`, and the mode is chosen using:
     - `if (n % 4 == 0) → Voltmeter`
     - `if (n % 4 == 1) → Ammeter`
     - `if (n % 4 == 2) → Ohmmeter`
     - `if (n % 4 == 3) → Diode/Continuity`

## Code Snippet
```cpp
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
