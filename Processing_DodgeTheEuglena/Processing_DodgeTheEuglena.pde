 /* 
Plug in a webcam microscope & an Arduino with TwoJoysticksCode.ino uploaded on it.
* Check out which webcam you need in the list, and fill in its number in the cameras[...] line in setup(). 
* The code is tweaked for the Logilink 640 px * 480 px webcam, change these values throughout if you use another type.
* Important parameters for Euglena tracking: DiffTreshold & pixelTreshold
* Currently the joystick communication is lagging, suggestions welcome=). 

Roland van dierendonck, June 2016

Edited by Pieter van Boheemen, October 2016

*/

import processing.serial.*; //import the Serial library
import gab.opencv.*;              // Load library https://github.com/atduskgreg/opencv-processing
import processing.video.*;        // Load video camera library 

/* Declare state-changing variables */
int state = 0;
final int MAIN_MENU = 0;
final int GAME_INFO = 1;
final int GAME = 2;
final int PAUSE = 3;
final int SERIAL_SETTINGS = 4;
final int CAMERA_SETTINGS = 5;
final int GAME_SETTINGS = 6;

boolean statePause = false;
int pauseFrames = 0;
int startPauseFrame = 0;

// Settings menu variables
int selectedItem = 0;
int selectedPort = 0;
int selectedCamera = 0;

/* Declare video variables */
Capture video;                    // Camera stream
OpenCV opencv;                    // OpenCV
PImage now, diff;                 // PImage variables to store the current image and the difference between two images 
String[] cameras = Capture.list();
int DiffTreshold = 37;            //  Sensitivity of the script
int movementAmount = 0;           //  Count the number of white pixels in the position of the spaceship
int pixelTreshold = 50;           // number of pixels in area Player before it respawns
boolean debugMode = false;

// Images
PImage WaagWetlabLogo;
PShape Spaceship;
PShape EuglenaLogo;

// Fonts
PFont ASExtraBoldItalic; 
PFont ASMedium;
PFont ASBoldItalic;
PFont ASLightItalic;

int textSizeSmall;
int textSizeBig;
int textSizeMedium;

// Score
int Lives = 3;
int FrameLivesStart = 0;
int score = 0;

// Player input
// Joystick position variables
int UD1 = 0;
int LR1 = 0;
int UD2 = 0;
int LR2 = 0;
// Variables for calibrating the middle position
int MIDUD1 = 0;
int MIDLR1 = 0;
int MIDUD2 = 0;
int MIDLR2 = 0;
boolean recalibrate = false;
// Minimal deviation from the middle before considering input as a move
int MIDerror = 20;

// Serial connection
String serial;   // Declare a new string called 'serial' . A string is a sequence of characters (data type know as "char")
Serial port;  // The serial port, this is a new instance of the Serial class (an Object)
int end = 10;    // the number 10 is ASCII for linefeed (end of serial.println), later we will look for this to break up individual messages
String UD1str = "UD1";
String LR1str = "LR1";
String UD2str = "UD2";
String LR2str = "LR2";

// Clock variables
int currentTime = 0; // current time in milliseconds
int currentSecs = 0; // current time in seconds
int stepTime = 0; // time of last step
int lastMenuTime = 0; // time for blinking menu item

int ImmortalTimeTreshold = 2; // First spawn immortal time
int ImmortalTimeStartTreshold = 10; // Respawn immortal time
int immortaltimesaver = 0; // Time of respawn

int TotalTime = 0; // Displayed game time

boolean immortalTimeStart = true; // Immortal flag
boolean immortalTimeGame = false; // Immortal flag after respwan

// Player position
int PlayerX = 0; 
int PlayerY = 0;  
int diameter = 100; //size of the spaceship in diameters

// Bubble variables are used for scoring the collision
int bubbleX;
int bubbleY;
int bubbleHeight;
int bubbleWidth;

void setup() {
  //size(500,500);
  fullScreen(1);
  
  // Player spawn position
  PlayerX = int(random(0, width));
  PlayerY = int(random(0, height)); 
  
  // Load images
  Spaceship = loadShape("Spaceship.svg");
  EuglenaLogo = loadShape("SpaceEuglenaLogo.svg");
  WaagWetlabLogo = loadImage("WetlabLogoTransparant.png");
 
  // Print list of available serial ports to console for debugging 
  printArray(Serial.list()); // print list of serial ports
  
  // Print list of available cameras to console for debugging
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i, cameras[i]);
    }
  } 
  
  // Load fonts
  ASExtraBoldItalic = loadFont("AlegreyaSansSC-ExtraBoldItalic-48.vlw");
  ASMedium = loadFont("AlegreyaSansSC-Medium-48.vlw");
  ASBoldItalic = loadFont("AlegreyaSansSC-BoldItalic-48.vlw");
  ASLightItalic = loadFont("AlegreyaSansSC-LightItalic-48.vlw"); 
  
  // Set text size relative to screen
  textSizeSmall = int(height/50);
  textSizeBig = int(height/ 15);
  textSizeMedium = int(height/25);
}

void draw() {
 background(100);

 // Updat clock variables
 currentTime = millis();
 currentSecs = int(currentTime/1000);

  switch(state) {
    case MAIN_MENU:
      // Draw Main Menu
      rectMode(CENTER);
      fill(255);
      noStroke();
      rect(width/2, height/2,width*0.9, height*0.9);
      textAlign(CENTER, TOP);
      fill(0);
      
      EuglenaLogo.disableStyle();  // Ignore the colors in the SVG
      shapeMode(CENTER);
      shape(EuglenaLogo, width/2, height/6, 300, 180);
      
      textFont(ASExtraBoldItalic, textSizeBig);
      text("~DODGE THE EUGLENA~", width/2, height/4);
      textFont(ASLightItalic, textSizeBig);
      
      // Blink menu
      if((currentTime-lastMenuTime) < 500) fill(255);
      else if(currentTime-lastMenuTime < 1000) fill(0); 
      else lastMenuTime = currentTime;
      
      text("Press key:", width/2, height/2-50);
      textFont(ASExtraBoldItalic, textSizeBig);
      fill(0);
      text("[1] Start Game", width/2, height/2);
      text("[2] Game Info", width/2, height/2+50);
      text("[3] Serial Settings", width/2, height/2+100);
      text("[4] Camera Settings", width/2, height/2+150);
      text("[5] Game Settings", width/2, height/2+200);
      
      imageMode(CENTER);
      image(WaagWetlabLogo, width/2, height-(height/5), 180, 54);
      imageMode(CORNERS);
      
      break;
    
    case GAME_INFO:
      // Draw Game Info
      rectMode(CENTER);
      fill(255);
      noStroke();
      rect(width/2, height/2,width*0.9, height*0.9);
      textAlign(CENTER, TOP);
      fill(0);
      EuglenaLogo.disableStyle();  // Ignore the colors in the SVG
      shapeMode(CENTER);
      shape(EuglenaLogo, width/2, height/6, 150, 90);
      
      textFont(ASExtraBoldItalic, textSizeBig);
      text("DODGE THE EUGLENA", width/2, height/4);
      textFont(ASLightItalic, textSizeMedium);
      text("The Euglena are trying to grab you!", width/2, height/2-90);
      text("Try to stay alive for as long as you can.", width/2, height/2-60);
      textFont(ASBoldItalic, textSizeMedium);
      text("Player 1:", width/2, height/2-30);
      textFont(ASLightItalic, textSizeMedium);
      text("Navigate your spaceship and dodge their attacks.", width/2, height/2);
      textFont(ASBoldItalic, textSizeMedium);
      text("Player 2:", width/2, height/2+30);
      textFont(ASLightItalic, textSizeMedium);
      text("Use keys [W], [A], [S] or [D] to guide the Euglena.", width/2, height/2+60);
      
      textFont(ASBoldItalic, textSizeMedium);
      textAlign(LEFT, TOP);
      text("[BACKSPACE] Back to Menu", 50, height-150);
      
      textAlign(CENTER, TOP);
      textFont(ASMedium, textSizeSmall);
      text("This game has been developed by Waag Society", width/2, height/2+180);
      text("Special thanks to: Pieter van Boheemen, Roland van Dierendonck, Christian Schultz", width/2, height/2+200);
      text("Inspired by: Riedel-Kruse Lab Stanford", width/2, height/2+220);
      
      imageMode(CENTER);
      image(WaagWetlabLogo, width/2, height-(height/5), 180, 54);
      imageMode(CORNERS);
      
      break;
    
    case SERIAL_SETTINGS:
      // Draw Settings
      rectMode(CENTER);
      fill(255);
      noStroke();
      rect(width/2, height/2,width*0.9, height*0.9);
      textAlign(CENTER, TOP);
      fill(0);
      EuglenaLogo.disableStyle();  // Ignore the colors in the SVG
      shapeMode(CENTER);
      shape(EuglenaLogo, width/2, height/6, 150, 90);
      
      textFont(ASExtraBoldItalic, textSizeBig);
      text("SERIAL SETTINGS", width/2, height/4);
      textFont(ASLightItalic, textSizeMedium);
      text("Select your Serial port [-] or [+]", width/2, height/2-75);
      
      textAlign(LEFT, TOP);
      String[] serialPorts = Serial.list();
      if(selectedItem > serialPorts.length-1) selectedItem = serialPorts.length-1;
      for(int i=0; i<serialPorts.length; i++) {
        if(i == selectedItem) {
          rect(width/2-120,height/2+50*i,10,10);
          selectedPort = selectedItem;
        }
        text(serialPorts[i], width/2-100, height/2+(50*i));
      }
      
      textFont(ASBoldItalic, textSizeMedium);
      textAlign(LEFT, TOP);
      text("[BACKSPACE] Back to Menu", 50, height-150);
      
      textAlign(CENTER, TOP);
      
    break;
    
    case CAMERA_SETTINGS:
      // Draw Settings
      rectMode(CENTER);
      fill(255);
      noStroke();
      rect(width/2, height/2,width*0.9, height*0.9);
      textAlign(CENTER, TOP);
      fill(0);
      EuglenaLogo.disableStyle();  // Ignore the colors in the SVG
      shapeMode(CENTER);
      shape(EuglenaLogo, width/2, height/6, 150, 90);
      
      textFont(ASExtraBoldItalic, textSizeBig);
      text("CAMERA SETTINGS", width/2, height/4);
      textFont(ASLightItalic, textSizeMedium);
      text("Select your Camera [-] or [+]", width/2, height/2-75);
      
      textFont(ASLightItalic, textSizeSmall);
      textAlign(LEFT, TOP);
      if(selectedItem > cameras.length-1) selectedItem = cameras.length-1;
      for(int i=0; i<cameras.length; i++) {
        if(i == selectedItem) {
          rect(width/2-120,height/2+20*i,10,10);
          selectedCamera = selectedItem;
        }
        text(cameras[i], width/2-100, height/2+(20*i));
      }
      
      textFont(ASBoldItalic, textSizeMedium);
      textAlign(LEFT, TOP);
      text("[BACKSPACE] Back to Menu", 50, height-150);
      
      textAlign(CENTER, TOP);
      
      break;
    
    case GAME:
     // Draw Game
     
     // Handle the image
     opencv.loadImage(video);   //  Capture video from camera in OpenCV
     now = opencv.getInput();   //  Store image in PImage
     image(video, 0, 0, width, height);        //  Draw camera image to screen 
      
     opencv.blur(3);                  //  Reduce camera noise            
     opencv.diff(now);                //  Difference between two pictures
     opencv.threshold(DiffTreshold);  //  Convert to Black and White
     diff = opencv.getOutput();       //  Store this image in an PImage variable
     
     // Show diff image for debugging
     if(debugMode) {
       fill(255,0,0);
       image(diff, 0, 0, width, height);
       textFont(ASExtraBoldItalic, textSizeSmall); 
       text("Difference Treshold "+DiffTreshold, width/2, height/2);
       text("Blob Size Treshold "+pixelTreshold, width/2, height/2+50);
     }
     
     // MAKE ACTIVE AGAIN WHEN ARDUINO IS CONNECTED
    
     // Let the player control the spaceship
     // Start with reading the values from the Arduino via the serial port
     while (port.available() > 0) { //as long as there is data coming from serial port, read it and store it 
       serial = port.readStringUntil(end);
     }
     if (serial != null) {  //if the string is not empty, print the following
     
       println(serial);
       String[] a = split(serial, ',');  //a new array (called 'a') that stores values into separate cells (separated by commas specified in your Arduino program)
         
       String joystick = a[0].trim();
       String valueJoystick = a[1].trim();
       int value = int(valueJoystick);
           
       if(joystick.equals(LR1str) == true) {
         LR1 = value;
       } else if (joystick.equals(LR2str) == true) {
         LR2 = value;
       } else if (joystick.equals(UD1str) == true) {
         UD1 = value;
       } else if (joystick.equals(UD2str) == true) {
         UD2 = value;
       }      
     }
      
     // Use the first 5 s to callibrate midpoints 
     if( currentTime < 5000 || recalibrate == true) {
       MIDUD1 = UD1;
       MIDLR1 = LR1;
       MIDUD2 = UD2;
       MIDLR2 = LR2; 
       recalibrate = false;
     } 
      
     // Print values to console for debugging
     //if(debugMode) {
       println("LR1 = " + LR1 + ", UD1 = " + UD1 + ", LR2 = " + LR2 + ", UD2 = " + UD2 + ", MIDUD1 = " + MIDUD1 + ", MIDLR1 = " + MIDLR1);
       //println(PlayerX, PlayerY);
     //println(diameter, width - diameter, diameter, height- diameter);
     //println(height/stepSize);
     //}
    
     // Move the spaceship within boundaries
     boolean up = false;
     boolean down = false;
     boolean left = false;    
     boolean right = false;
     // We keep track of time to prevent moving to fast
     if(currentTime - stepTime > 50) {
       /*if((UD1 > MIDUD1 + MIDerror)&&(PlayerY < height - diameter - height/10)){
         PlayerY = PlayerY + diameter;
         stepTime = currentTime;
         up = true;
       } 
       if((UD1 < MIDUD1 - MIDerror)&&(PlayerY > diameter)){ 
         PlayerY = PlayerY - diameter;
         stepTime = currentTime;
         down = true;
       } 
       if((LR1 > MIDLR1 + MIDerror)&&(PlayerX < width - diameter)){
         PlayerX = PlayerX + diameter;
         stepTime = currentTime;
         right = true;
       } 
       if((LR1 < MIDLR1 - MIDerror)&&(PlayerX > diameter)){
         PlayerX = PlayerX - diameter;
         stepTime = currentTime;
         left = true;
       } */
     
       
       PlayerX = int(float(LR1)/float(255)*width);
       PlayerY = int(float(UD1)/float(255)*height);
     }
    
     // Draw Player
     stroke(0,0,255);
     if (immortalTimeGame == true){ // blue is immortal
       fill(0, 0, 255);
     }  else {
       fill(0,255,0); // green is mortal
     }
     
     // Render players as a dot
     //ellipseMode(CENTER);
     //ellipse(PlayerX, PlayerY, diameter, diameter);
     
     // Render player as spaceship
     Spaceship.disableStyle();  // Ignore the colors in the SVG
     shapeMode(CENTER);
     shape(Spaceship, PlayerX, PlayerY, 100, 200);
     // rotate according to direction
     if(up) {
       if(right) {
         Spaceship.rotate(radians(45));
       }
       else if(left) {
         Spaceship.rotate(radians(-45));
       }
       else {
          // stay in position
       }
     }
     if(down) {
       if(right) {
         Spaceship.rotate(radians(135));
       }
       else if(left) {
         Spaceship.rotate(radians(225));
       }
       else {
         Spaceship.rotate(radians(180));
       }
     }
     
     // Substract starting time
     TotalTime = currentSecs - 10; 
         
     // Top Bar
     fill(0);
     stroke(0,0,0);
     rect(0, 0, width*2, height/10);
      
     // Logo
     fill(255);
     EuglenaLogo.disableStyle();  // Ignore the colors in the SVG
     shapeMode(CENTER);
     shape(EuglenaLogo, width/2-100, height/40+5, 50, 30);
     textAlign(LEFT, TOP);
     textFont(ASExtraBoldItalic, textSizeSmall); 
     text("~DODGE THE EUGLENA~", width/2-80, height/40);
      
     // Score
     textFont(ASBoldItalic, textSizeSmall);                     //  Set font size
     if(Lives > 0) score++;
     text("Score: " + (score),width * 0.05, height/40);
     textAlign(LEFT, TOP);
     text("Total Game Time: " + TotalTime, width * 0.80, height/40);
     text("Lives: " + Lives, width * 0.70, height/40);
      
     // Draw start screen
     if (immortalTimeStart == true){
       rectMode(CENTER);
       fill(255);
       noStroke();
       rect(width/2, height/2,width*0.9, height*0.9);
       textAlign(CENTER, TOP);
       fill(0);
       textFont(ASExtraBoldItalic, textSizeBig);
       text("~DODGE THE EUGLENA~", width/2, height/2);
       text("Get Ready...", width/2, height/2+75);
     }
     if(Lives < 0) {
       rectMode(CENTER);
       fill(255);
       noStroke();
       rect(width/2, height/2,width*0.9, height*0.9);
       textAlign(CENTER, TOP);
       fill(0);
       textFont(ASExtraBoldItalic, textSizeBig);
       text("GAME OVER", width/2, height/2);
       text("Total Score: " + score, width/2, height/2+75);
       
       if((currentTime-lastMenuTime) < 500) fill(255);
       else if(currentTime-lastMenuTime < 1000) fill(0); 
       else lastMenuTime = currentTime;
       text("Pres [X] to start again", width/2, height/2+150);
     }
     
      // Use white pixels for detection
      // update spaceship vars
      bubbleX = int(float(PlayerX)/ width * 640);
      bubbleY = int(float(PlayerY)/ height * 480);
      bubbleHeight = int(float(diameter)/height * 480);
      bubbleWidth = bubbleHeight;
    
      movementAmount = 0;
      
      //  For loop that cycles through all of the pixels in the area the spaceship occupies
      for( int y = bubbleY; y < (bubbleY + (bubbleHeight-1)); y++ ){   
        for( int x = bubbleX; x < (bubbleX + (bubbleWidth-1)); x++ ){
          //  If the current pixel is within the screen bondaries
          if ( x< 640 && x > 0 && y < 480 && y > 0 ){
            //  and if the brightness is above 127 (in this case, if it is white)
            if (brightness(diff.pixels[x + (y * 640)]) > 127) {
               movementAmount++;  //  Add 1 to the movementAmount variable.
            }
          }
        }
      }
      
      // check whether player is still immortal
      if (currentSecs >= ImmortalTimeStartTreshold) {
        immortalTimeStart = false;
      }  
      if ((currentSecs - immortaltimesaver) >= ImmortalTimeTreshold){
        immortalTimeGame = false;
      }    
        
      if ((movementAmount > pixelTreshold) && immortalTimeStart == false && immortalTimeGame == false ){ 
        //  If more than 5 pixels of movement are detected in the bubble area
        immortaltimesaver = currentSecs; // reset immortal timer
        immortalTimeGame = true; // Set immortal true
        Lives --; // substract one life
     
        // Respawn player at a random location
        PlayerX = int(random(10, width-10));
        PlayerY = int(random(10, height-height/10)); 
      }
      
      if(debugMode) println(currentSecs, immortalTimeStart, immortalTimeGame);
      
      fill(255);
      rectMode(CENTER);
      rect(width-100,height-40,200,80);
      fill(0);
      textFont(ASBoldItalic, textSizeSmall);
      textAlign(CENTER);
      text("Biotic Gaming by",width-100,height-62);
      imageMode(CENTER);
      image(WaagWetlabLogo, width-100, height-31, 180, 54);
      imageMode(CORNERS);
    
      break;
    
    case PAUSE:
      //Draw pause screen
      break;
  }
  
}

/* Capture function */
void captureEvent(Capture c) {
 c.read();
}

void keyPressed() {
  if(key == ' '){ // restart game
    if(statePause) {
      statePause = false;
      state = 2;
      pauseFrames = frameCount - startPauseFrame;
    }
    else {
      state = 3;
      statePause = true;
      startPauseFrame = frameCount;
      textAlign(CENTER, TOP);
      fill(255);
      textFont(ASExtraBoldItalic, textSizeBig);
      text("PAUSE", width/2, height/2);
    }
  }
  if(key == 'w'){
    println("UP");
    port.write('w');
  }
  if(key == 's'){
    println("DWN");
    port.write('s');
  }
  if(key == 'a'){
    println("LEFT");
    port.write('a');
  }
  if(key == 'd'){
    println("RT");
    port.write('d');
  }
  if(key == 'r'){
    port.write('r');
    recalibrate = true;
    println("RECALLIBRATE");
  }
  if(key == 'p'){
    port.write('p');
    println("Increase Brightness");
  }
  if(key == 'l'){
    port.write('l');
    println("Decrease Brightness");
  }
  if(key == 'o'){
    DiffTreshold = DiffTreshold + 1;
    print("DiffTreshold = ");
    println(DiffTreshold);
  }
  if(key == 'k'){
    DiffTreshold = DiffTreshold - 1;
    if(DiffTreshold < 0) DiffTreshold = 0;
    print("DiffTreshold = ");
    println(DiffTreshold);
  }
  if(key == 'u'){
    pixelTreshold++;
    print("pixelTreshold = ");
    println(pixelTreshold);
  }
  if(key == 'h'){
    pixelTreshold--;
    if(pixelTreshold < 0) pixelTreshold = 0;
    print("pixelTreshold = ");
    println(pixelTreshold);
  }
  if(key == 'x'){ // Restart game
    Lives = 3;
    score = 0;
    immortalTimeStart = true;
    ImmortalTimeStartTreshold = currentSecs + 5;
    FrameLivesStart = frameCount;
  }
  if(key == 'i') {
    if(debugMode) debugMode = false;
    else debugMode = true;
  }
  if(key == 'g') {
    saveFrame();
  }
  if(key == '2') state = 1;
  if(key == '1') { 
    // Start the game
    state = 2;
    Lives = 3;
    FrameLivesStart = frameCount;
    score = 0;
    
    // Open serial connection
    port = new Serial(this, Serial.list()[selectedPort], 9600); // initializing the object by assigning a port and baud rate (must match that of Arduino)
    port.clear();  // function from serial library that throws out the first reading, in case we started reading in the middle of a string from Arduino
    serial = port.readStringUntil(end); // function that reads the string from serial port until a println and then assigns string to our string variable (called 'serial')
    serial = null; // initially, the string will be null (empty)
    
    // Select the webcam
    video = new Capture(this, 640, 480, Capture.list()[selectedCamera], 30);    //  Define video size, with webcam plugged in
    //  video = new Capture(this, 640, 480, cameras[8], 30); 
    opencv = new OpenCV(this, 640, 480);    //  Define opencv size
    video.start();  
    
    ImmortalTimeStartTreshold = currentSecs + 5;
  }
  if(key == '3') state = 4;
  if(key == '4') state = 5;
  if(key == '5') state = 6;
  if(key == '6') state = 0;
  if(key == BACKSPACE) state = 0;
  if(key == CODED) {
    if(keyCode == DOWN) {
      selectedItem++;
    }
    if(keyCode == UP) {
      selectedItem--;
      if(selectedItem < 0) {
        selectedItem = 0;
      }
    }
  }
}