/* Modified from Philip Vallone
2-axis joystick connected to an Arduino Micro
to output 4 pins, up, down, left & right
If you are using pull down resistors, change all the HIGHs to LOWs and LOWs to HIGH.
This skectch is using pull up resistors.
*/

/*Currently LEDs light up for 400 ms (Delay on bottom)
This can be altered to check effect.
Also, the LEDs are connected to PWM Arduino pins,
so you can change the code to alter their strength. 
*/

/* ints for storing values */
int UD = 0;
int LR = 0;

int UD2 = 0;
int LR2 = 0;

int SW1 = 0;
int SW2 = 0;

/* Switch pins */
int ISW1 = 2;
int ISW2 = 4;

/* Arduino Micro output pins*/
int DWN = 11;
int UP = 10;
int LEFT = 9;
int RT = 6;
/* Arduino Micro Input Pins */
int IUP=A0;
int ILR=A1;
// copied for joystick 2
int IUP2=A2;
int ILR2=A3;

int MID = 10; // 10 mid point delta arduino, use 4 for attiny
int LRMID = 0;
int UPMID = 0;
// copied for joystick 2
int LRMID2 = 0;
int UPMID2 = 0;
void setup(){
  
  Serial.begin(9600);
  pinMode(DWN, OUTPUT);
  pinMode(UP, OUTPUT);
  pinMode(LEFT, OUTPUT);
  pinMode(RT, OUTPUT);

  digitalWrite(DWN, HIGH);
  digitalWrite(UP, HIGH);
  digitalWrite(LEFT, HIGH);
  digitalWrite(RT, HIGH);
  
  pinMode(ISW1, INPUT);
  pinMode(ISW2, INPUT);

  //calibrate center
  LRMID = analogRead(ILR);
  UPMID = analogRead(IUP);
  
   //calibrate center joystick 2
  LRMID2 = analogRead(ILR2);
  UPMID2 = analogRead(IUP2);
}

void loop(){

  UD = analogRead(IUP);
  LR = analogRead(ILR);
  
  String stringUD = "UD1,";
  String stringUDdata = stringUD + UD;
  Serial.println(stringUDdata);
  
  String stringLR = "LR1,";
  String stringLRdata = stringLR + LR;
  Serial.println(stringLRdata);
  
  UD2 = analogRead(IUP2);
  LR2 = analogRead(ILR2);
  
   String stringUD2 = "UD2,";
  String stringUD2data = stringUD2 + UD2;
  Serial.println(stringUD2data);
  
  String stringLR2 = "LR2,";
  String stringLR2data = stringLR2 + LR2;
  Serial.println(stringLR2data);
  
  SW1 = digitalRead(ISW1);
  SW2 = digitalRead(ISW2);
  
   String stringSW1 = "SW1,";
  String stringSW1data = stringSW1 + SW1;
  Serial.println(stringSW1data);
  
  String stringSW2 = "SW2,";
  String stringSW2data = stringSW2 + SW2;
  Serial.println(stringSW2data);
  
  
//  Serial.println(UD);
//  Serial.println(LR);
 // Serial.println("UD: " + UD + ", LR: " + LR);
  
  // UP-DOWN
  if(UD < UPMID - MID){
   digitalWrite(DWN, HIGH);
  }else{
   digitalWrite(DWN, LOW);
  }

  if(UD > UPMID + MID){
   digitalWrite(UP, HIGH);
  }else{
   digitalWrite(UP, LOW);
  }
  // LEFT-RIGHT
  if(LR < LRMID - MID){
   digitalWrite(LEFT, HIGH);
  }else{
   digitalWrite(LEFT, LOW);
  }

  if(LR > LRMID + MID){
   digitalWrite(RT, HIGH);
  }else{
   digitalWrite(RT, LOW);
  }

  delay(10);


}
