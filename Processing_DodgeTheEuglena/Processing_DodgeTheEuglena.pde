 /* 
Plug in a webcam microscope & an Arduino with TwoJoysticksCode.ino uploaded on it.
* Check out which webcam you need in the list, and fill in its number in the cameras[...] line in setup(). 
* The code is tweaked for the Logilink 640 px * 480 px webcam, change these values throughout if you use another type.
* Important parameters for Euglena tracking: DiffTreshold & pixelTreshold
* Currently the joystick communication is lagging, suggestions welcome=). 

Roland van dierendonck, June 2016

*/

import processing.serial.*; //import the Serial library
import gab.opencv.*;              // Load library https://github.com/atduskgreg/opencv-processing
import processing.video.*;        // Load video camera library 

/* Declare variables */
Capture video;                    // Camera stream
OpenCV opencv;                    // OpenCV
PImage now, diff;                 // PImage variables to store the current image and the difference between two images 
PShape Spaceship;

PFont ASExtraBoldItalic; 
PFont ASMedium;
PFont ASBoldItalic;
PFont ASLightItalic;

int textSizeSmall;
int textSizeBig;
int textSizeMedium;

// PFont font;                       //  A new font object
// DiffTreshold was 50
int DiffTreshold = 20;            //  Sensitivity of the script
int pixelTreshold = 50;             // number of pixels in area Player before it respawns

int poppedPlayers;                //  Count total number of popped players


int end = 10;    // the number 10 is ASCII for linefeed (end of serial.println), later we will look for this to break up individual messages

int Lives = 3;
// initializing VARs for joystick positions
int UD1 = 0;
int LR1 = 0;
  
int UD2 = 0;
int LR2 = 0;

int MIDUD1 = 0;
int MIDLR1 = 0;
int MIDUD2 = 0;
int MIDLR2 = 0;

// Error for wobbly Joystick values
int MIDerror = 20;

String UD1str = "UD1";
String LR1str = "LR1";
String UD2str = "UD2";
String LR2str = "LR2";

String serial;   // declare a new string called 'serial' . A string is a sequence of characters (data type know as "char")
Serial port;  // The serial port, this is a new instance of the Serial class (an Object)

int currentTime = 0; 
int currentSecs = 0;
int stepTime = 0; 

int ImmortalTimeTreshold = 2; // for starting up and setting parameters, change later into 2
int ImmortalTimeStartTreshold = 10;
int immortaltimesaver = 0;

int TotalTime = 0;

boolean immortalTimeStart = true;
boolean immortalTimeGame = false;



int PlayerX = 0; 
int PlayerY = 0;  

// Size variables
int stepSize = 20;
int diameter = 0;

int movementAmount = 0;          //  Create and set a variable to hold the amount of white pixels detected in the area where the bubble is


// initialize bubble variables, used to scale down fullScreen info to 640,480 
int bubbleX;
int bubbleY;
int bubbleHeight;
int bubbleWidth;



boolean fillRed = false;

void setup() {
    size(500,500);
 //  fullScreen(2);
  
  // update vars based on width/ height
  PlayerX = int(random(0, width));
  PlayerY = int(random(0, height)); 
  
  diameter = height/20;
  
  Spaceship = loadShape("Spaceship.svg");
 
  
 /// MAKE ACTIVE AGAIN WITH ARDUINO CONNECTED!
 
 
  // Setting up serial port   
  port = new Serial(this, Serial.list()[0], 9600); // initializing the object by assigning a port and baud rate (must match that of Arduino)
  port.clear();  // function from serial library that throws out the first reading, in case we started reading in the middle of a string from Arduino
  serial = port.readStringUntil(end); // function that reads the string from serial port until a println and then assigns string to our string variable (called 'serial')
  serial = null; // initially, the string will be null (empty)
  
      // Select camera: print all available cameras in a list
    String[] cameras = Capture.list();
    if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    } else {
      println("Available cameras:");
      for (int i = 0; i < cameras.length; i++) {
        println(i, cameras[i]);
      }
    }      
    // select the number of the webcam camera from the list
    video = new Capture(this, 640, 480, cameras[12], 30);    //  Define video size, with webcam plugged in
  //  video = new Capture(this, 640, 480, cameras[8], 30); 
    opencv = new OpenCV(this, 640, 480);    //  Define opencv size
  
    video.start();   
  
    ASExtraBoldItalic = loadFont("AlegreyaSansSC-ExtraBoldItalic-48.vlw");
    ASMedium = loadFont("AlegreyaSansSC-Medium-48.vlw");
    ASBoldItalic = loadFont("AlegreyaSansSC-BoldItalic-48.vlw");
    ASLightItalic = loadFont("AlegreyaSansSC-LightItalic-48.vlw"); 
    
    textSizeSmall = int(height/50);
    textSizeBig = int(height/ 10);
    textSizeMedium = int(height/25);
}

void draw() {
  //background(255);
  
   opencv.loadImage(video);   //  Capture video from camera in OpenCV
 now = opencv.getInput();   //  Store image in PImage
 image(video, 0, 0, width, height);        //  Draw camera image to screen 
  
 opencv.blur(3);                  //  Reduce camera noise            
 opencv.diff(now);                //  Difference between two pictures
 opencv.threshold(DiffTreshold);  //  Convert to Black and White
 diff = opencv.getOutput();       //  Store this image in an PImage variable
 
 // show diff image for debugging
// image(diff, 0, 0, width, height);
  
  currentTime = millis();
  currentSecs = int(currentTime/1000);
 
 // MAKE ACTIVE AGAIN WHEN ARDUINO IS CONNECTED
 
 
 
  
  // Reading out joystick values
  while (port.available() > 0) { //as long as there is data coming from serial port, read it and store it 
    serial = port.readStringUntil(end);
  }
  if (serial != null) {  //if the string is not empty, print the following
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
  
  // Use the first X ms to callibrate midpoints 
  if( currentTime < 10000) {
    MIDUD1 = UD1;
    MIDLR1 = LR1;
    MIDUD2 = UD2;
    MIDLR2 = LR2; 
  } 
  
  // print for debugging
   //  println("LR1 = " + LR1 + ", UD1 = " + UD1 + ", LR2 = " + LR2 + ", UD2 = " + UD2 + ", MIDUD1 = " + MIDUD1 + ", MIDLR1 = " + MIDLR1);
   //println(PlayerX, PlayerY);
   //println(diameter, width - diameter, diameter, height- diameter);
   //println(height/stepSize);

  // Movement within boundaries
  if(currentTime - stepTime > 50) {
      if((UD1 > MIDUD1 + MIDerror)&&(PlayerY < height - diameter)){
        PlayerY = PlayerY + diameter;
        stepTime = currentTime;
      } 
      if((UD1 < MIDUD1 - MIDerror)&&(PlayerY > diameter)){ 
        PlayerY = PlayerY - diameter;
        stepTime = currentTime;
      } 
      if((LR1 > MIDLR1 + MIDerror)&&(PlayerX < width - diameter)){
        PlayerX = PlayerX + diameter;
        stepTime = currentTime;
      } 
      if((LR1 < MIDLR1 - MIDerror)&&(PlayerX > diameter)){
        PlayerX = PlayerX - diameter;
        stepTime = currentTime;
      }
      
  }
  
  

  // Draw Player
  stroke(0,0,255);
  if (immortalTimeGame == true){
    fill(0, 0, 255);
  }  else {
        fill(0,255,0);
      }
  
  //Spaceship.disableStyle();  // Ignore the colors in the SVG
  //shapeMode(CENTER);
  //shape(Spaceship, PlayerX, PlayerY, diameter, diameter);
      
  ellipseMode(CENTER);
  ellipse(PlayerX, PlayerY, diameter, diameter);
  
  TotalTime = currentSecs - 10; 
  
  // KEEP COMMMENTED OUT: TEXT CHOICES
    //ASExtraBoldItalic = loadFont("AlegreyaSansSC-ExtraBoldItalic-48.vlw");
    //ASMedium = loadFont("AlegreyaSansSC-Medium-48.vlw");
    //ASBoldItalic = loadFont("AlegreyaSansSC-BoldItalic-48.vlw");
    //ASLightItalic = loadFont("AlegreyaSansSC-LightItalic-48.vlw"); 
    
    
  // Text 
   textFont(ASMedium, textSizeSmall);                     //  Set font size
   fill(0);
  textAlign(LEFT, TOP);
  text("you are in frame: " + frameCount,width * 0.05, height * 0.05);
  textAlign(LEFT, TOP);
  text("Total time: " + TotalTime, width * 0.95, height * 0.05);
  text("Lives: " + Lives, width * 0.95, height * 0.15);
  
  // Draw start screen
   if (immortalTimeStart == true){
    rectMode(CENTER);
    fill(255);
    noStroke();
    rect(width/2, height/2,width*0.9, height*0.9);
    textAlign(CENTER, TOP);
    fill(0);
    textFont(ASExtraBoldItalic, textSizeBig);
    text("BIOTIC GAME: DODGE THE EUGLENA", width/2, height/2);
    
  } 
 
 // Use white pixels for detection
   // update bubble vars
   bubbleX = int(float(PlayerX)/ width * 640);
   bubbleY = int(float(PlayerY)/ height * 480);
   bubbleHeight = int(float(diameter)/height * 480);
   bubbleWidth = bubbleHeight;

  movementAmount = 0;
  
    for( int y = bubbleY; y < (bubbleY + (bubbleHeight-1)); y++ ){   //  For loop that cycles through all of the pixels in the area the bubble occupies
     for( int x = bubbleX; x < (bubbleX + (bubbleWidth-1)); x++ ){
       if ( x< 640 && x > 0 && y < 480 && y > 0 ){             //  If the current pixel is within the screen bondaries
         if (brightness(diff.pixels[x + (y * 640)]) > 127)        //  and if the brightness is above 127 (in this case, if it is white)
         {
           movementAmount++;  //  Add 1 to the movementAmount variable.
          
         }
       }
     }
    }
    
    if (currentSecs >= ImmortalTimeStartTreshold) {
      immortalTimeStart = false;
    }
    
    if ((currentSecs - immortaltimesaver) >= ImmortalTimeTreshold){
      immortalTimeGame = false;
    }    
    
//    println("movementAmount = " + movementAmount);
    if ((movementAmount > pixelTreshold) && immortalTimeStart == false && immortalTimeGame == false ){ //  If more than 5 pixels of movement are detected in the bubble area
    
  immortaltimesaver = currentSecs;
  immortalTimeGame = true;
  Lives --;
  
  PlayerX = int(random(0, width));
  PlayerY = int(random(0, height)); 
  
  }
  
  println(currentSecs, immortalTimeStart, immortalTimeGame);

 
}

/* Capture function */
void captureEvent(Capture c) {
 c.read();
}