import websockets.*;
import tramontana.library.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.event.KeyEvent;

Robot rbt;

Tramontana phone;

Toolkit toolkit=Toolkit.getDefaultToolkit();

String menuMode = "profile";

float yaw1 = 0.0f;
float pitch1 = 0.0f;
float roll1 = 0.0f;

int w = 0;
int h = 0;

float mx;
float my;

float mx2;
float my2;

float px;
float py;

float thresh = 0.002f;

int tDown;


//###    Mouse button locations on virtual mouse in x/y coords    ###

float m1 = (374/7)*3;
float m2 = (374/5)*4;

int y2;

float accel;
String IP = "";
String NAME = "";

float[] AH = {0, 0};
int inactive = 0;

String[] lines;

float rollMax;
float rollMid;
float rollMin;

float pitchMax;
float pitchMid;
float pitchMin;

float rollMulti;
float pitchMulti;

int averageSize = 5;

float[] xa = {};
float[] ya = {};



void settings() {
  size(250,150);
}

void setup() {
  noStroke();
  w = toolkit.getScreenSize().width;
  h = toolkit.getScreenSize().height;
  
  surface.setLocation((w/2)-125, (h/2)-75);
  surface.setTitle("Wireless Mouse");
  surface.setResizable(true);
  
  try {
    rbt = new Robot();
  } catch(Exception e) {
    e.printStackTrace();
  }
  
  textSize(12);
  
  lines = loadStrings("data/profiles.txt");
  saveStrings("data/profiles.txt", lines);
  
  for (int i = 0; i < averageSize; i++) {
    xa = append(xa, 0);
    ya = append(ya, 0);
  }
}

void draw() {
  if (menuMode == "profile") {
    fill(255);
    rect(0,0,250,150);
    fill(0);
    text("PROFILES (Press number key to select)",10,20);
    for (int i = 0; i < lines.length/2; i++) {
      text(i+1 + ":  " + lines[(i*2)+1] + ": " + lines[(i*2)+2],10,20*(i+2));
    }
  } else if (menuMode == "newProfileName") {
    fill(255);
    rect(0,0,250,150);
    fill(0);
    text("Add profile name",10,20);
    text("Press enter to finalize",120,20);
    text("Name: " + NAME,20,60);
  } else if (menuMode == "newProfileIP") {
    fill(255);
    rect(0,0,250,150);
    fill(0);
    text("Add profile IP",10,20);
    text("Press enter to finalize",120,20);
    text("IP: " + IP,20,60);
  } else if (menuMode == "initialize") {
    
    //###    Set up the phone    ###
    
    phone = new Tramontana(this,IP);
    phone.subscribeAttitude(60);
    phone.subscribeTouch();
    phone.subscribeTouchDrag();
    phone.setBrightness(0.5f);
    phone.makeVibrate();
    menuMode = "calibrateTR";
  } else if (menuMode == "calibrateTR") {
    surface.setLocation(-8,0);
    surface.setSize(w,h-30);
    phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/747854729219932271/Mouse_MouseCalibrateTL.png");
    fill(255);
    rect(0,0,w,h-30);
    fill(69,114,227);
    circle(w-60,30,50);
    fill(0);
    textSize(28);
    text("Point your phone at the blue dot and tap the screen",(w/2)-340,(h/2)-14);
  } else if (menuMode == "calibrateBL") {
    fill(255);
    rect(0,0,w,h-30);
    fill(69,114,227);
    circle(60,h-90,50);
    fill(0);
    textSize(28);
    text("Point your phone at the blue dot and tap the screen",(w/2)-340,(h/2)-14);
  } else if (menuMode == "initRun") {
    rollMid = (rollMax+rollMin)/2;
    pitchMid = (pitchMax+pitchMin)/2;
    
    rollMulti = (w - 120) / (rollMax-rollMin);
    pitchMulti = (h - -120) / (pitchMax-pitchMin);
    
    surface.setSize(250,150);
    surface.setLocation((w/2)-125, (h/2)-75);
    
    menuMode = "run";
  } else if (menuMode == "run") {
    
    //Run the mouse
    runMouse();
  }
  
  if (menuMode == "run" || menuMode == "off" || menuMode == "calibrateTR" || menuMode == "calibrateBL") {
    if (menuMode == "run" || menuMode == "off") {
      fill(255);
      rect(0,0,250,150);
      fill(0);
      textSize(12);
      text("Minimize window",75,75);
    }
    
    //###    Data logging    ###
    
    //println("Pitch: " + pitch1);
    //println("Roll: " + roll1);
    //println(inactive);
    
    //###    Activity check    ###
    
    AH = splice(AH, pitch1 + roll1, 0);
    AH = shorten(AH);
    
    if (AH[0] == AH[1]) {
      inactive++;
      if (inactive > 120) {
        menuMode = "off";
        fill(255);
        rect(0,0,250,150);
        fill(0);
        text("Connection lost",75,75);
      }
    } else {
      inactive = 0;
    }
  }
}

void keyPressed() {
  
  //###    Menu options key controls    ###
  
  if (menuMode == "profile") {
    if (key == '1') {
      menuMode = "newProfileName";
    } else {
      String profileSelect = str(key);
      IP = lines[((PApplet.parseInt(profileSelect)-1)*2)+2];
      menuMode = "initialize";
    }
  } else if (menuMode == "newProfileName") {
    
    //Adding profile name
    
    if (key == BACKSPACE) {
      NAME = NAME.substring(0, NAME.length()-1);
    } else if (key == ENTER || key == RETURN) {
      menuMode = "newProfileIP";
    } else if (keyCode != CONTROL && keyCode != ALT && keyCode != SHIFT && key != TAB && key != DELETE) {
      NAME = NAME + key;
    }
  } else if (menuMode == "newProfileIP") {
    
    //Adding profile IP
    
    if (key == BACKSPACE) {
      IP = IP.substring(0, IP.length()-1);
    } else if (key == ENTER || key == RETURN) {
      lines = append(lines, NAME);
      lines = append(lines, IP);
      saveStrings("data/profiles.txt", lines);
      menuMode = "initialize";
    } else if (keyCode != CONTROL && keyCode != ALT && keyCode != SHIFT && key != TAB && key != DELETE) {
      IP = IP + key;
    }
  }
}

void runMouse() {
  if (menuMode == "run") {
    
    px = (roll1-rollMid)*-(rollMulti);
    py = (pitch1-pitchMid)*-(pitchMulti);
    
    xa = splice(xa, px, 0);
    xa = shorten(xa);
    ya = splice(ya, py, 0);
    ya = shorten(ya);
    
    mx = 0;
    my = 0;
    for (int i = 0; i < averageSize; i++) {
      mx += xa[i];
      my += ya[i];
    }
    mx = mx/averageSize;
    my = my/averageSize;
    
    
    mx2 -= (mx2 - mx) * 0.5f;
    my2 -= (my2 - my) * 0.5f;
    
    if (tDown == 0) {
      rbt.mouseMove(  PApplet.parseInt(mx2+w/2), PApplet.parseInt(my2+h/2)  );
    }
    rbt.mouseWheel(PApplet.parseInt(accel));
    accel = accel*0.8f;
    
  }
}

void onTouchDragEvent(String ipAddress, int x,int y) {
  if (x > m1 && x < m2 && y < 520) {
    accel += (y-y2)/10;
    if (y > y2+10 || y < y2-10) {
      y2 = y;
    }
  }
}

void onTouchDownEvent(String ipAddress, int x,int y) {
  //max x 374, max y 660
  tDown = 1;
  if (menuMode == "run") {
    if (x < m1) {
      rbt.mousePress(InputEvent.BUTTON1_DOWN_MASK);
      phone.setBrightness(0.5f);
      phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601362292506624/Mouse_MouseM1.png");
    }
    if (x > m2) {
      phone.setBrightness(0.5f);
      phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601366906109975/Mouse_MouseM2.png");
    }
    if (x > m1 && x < m2 && y < 520) {
      y2 = y;
      phone.setBrightness(0.5f);
      phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601372908158987/Mouse_MouseM3.png");
    }
  } else if (menuMode == "calibrateTR") {
    phone.makeVibrate();
    rollMin = roll1;
    pitchMax = pitch1;
    menuMode = "calibrateBL";
  } else if (menuMode == "calibrateBL") {
    phone.makeVibrate();
    rollMax = roll1;
    pitchMin = pitch1;
    menuMode = "initRun";
  }
  
  if (x > (374/3) && x < (374/3)*2 && y > 520) {
    if (menuMode == "run") {
      phone.makeVibrate();
      menuMode = "off";
    } else if (menuMode == "off") {
      phone.makeVibrate();
      menuMode = "run";
    }
  }
  
}

void onTouchEvent(String ipAddress, int x,int y) {
  
  tDown = 0;
  if (menuMode == "run") {
    if (x < m1) {
      rbt.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
    }
    if (x > m2) {
      rbt.mousePress(InputEvent.BUTTON3_DOWN_MASK);
      rbt.mouseRelease(InputEvent.BUTTON3_DOWN_MASK);
    }
    
    phone.setBrightness(0.5f);
    phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601357166936077/Mouse_Mouse.png");
  } else if (menuMode == "off") {
    phone.setBrightness(0.1f);
    phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677605309702733845/Mouse_MouseOff.png");
  }
}

void onAttitudeEvent(String ipAddress, float yaw, float pitch, float roll) {
  if (tDown == 0) {
    yaw1 = yaw;
    pitch1 = pitch;
    roll1 = roll;
  } else {
    if ((pitch > pitch1+thresh || pitch < pitch1-thresh) && (roll > roll1+thresh || roll < roll1-thresh)) {
      tDown = 0;
    }
  }
}
