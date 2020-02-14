import websockets.*;
import tramontana.library.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.event.KeyEvent;

Robot rbt;

Tramontana phone;

Toolkit toolkit=Toolkit.getDefaultToolkit();

int mouseOn = 1;

int setup;
int live;

float yaw1;
float pitch1;
float roll1;

int w = 0;
int h = 0;

float mx;
float my;

float px;
float py;

float thresh = 0.002;

int tDown;

float m1 = (374/7)*3;
float m2 = (374/5)*4;

int y2;

float accel;
String IP = "";

void setup() {
  size(250,150);
  noStroke();
  w = toolkit.getScreenSize().width;
  h =toolkit.getScreenSize().height;
    
  try {
    rbt = new Robot();
  } catch(Exception e) {
    e.printStackTrace();
  }
}

void draw() {
  if (live == 1) {
    if (setup == 1) {
      phone = new Tramontana(this,IP);
      phone.subscribeAttitude(60);
      phone.subscribeTouch();
      phone.subscribeTouchDrag();
      phone.setBrightness(0.5);
      phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601357166936077/Mouse_Mouse.png");
      fill(255);
      rect(0,0,250,150);
      fill(0);
      text("Minimize window",75,75);
      setup = 0;
    }
    if (mouseOn == 1) {
      //if (tDown == 0) {
        px = roll1*-(w*1.5);
        py = pitch1*-(w*1.5);
      //}
      mx -= (mx - px) * 0.3;
      my -= (my - py) * 0.3;
      
      if (tDown == 0) {
        rbt.mouseMove(  int(mx+w/2), int(my+h/2)  );
      }
      rbt.mouseWheel(int(accel));
      accel = accel*0.8;
    }
  } else {
    fill(255);
    rect(0,0,250,150);
    fill(0);
    text("Add phone IP",10,20);
    text("Press enter to finalize",120,20);
    text("IP: " + IP,20,60);
  }
}

void keyPressed() {
  if (live == 0) {
    if (key == BACKSPACE) {
      IP = IP.substring(0, IP.length()-1);
    } else if (key == ENTER) {
      setup = 1;
      live = 1;   
      rbt.mouseMove(w/2,h/2);
    } else {
      IP = IP + key;
    }
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
  if (mouseOn == 1) {
    if (x < m1) {
      rbt.mousePress(InputEvent.BUTTON1_DOWN_MASK);
      phone.setBrightness(0.5);
      phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601362292506624/Mouse_MouseM1.png");
    }
    if (x > m2) {
      phone.setBrightness(0.5);
      phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601366906109975/Mouse_MouseM2.png");
    }
    if (x > m1 && x < m2 && y < 520) {
      y2 = y;
      phone.setBrightness(0.5);
      phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601372908158987/Mouse_MouseM3.png");
    }
  }
  if (x > (374/3) && x < (374/3)*2 && y > 520) {
    phone.makeVibrate();
    if (mouseOn == 1) {
      mouseOn = 0;
      phone.releaseAttitude();
    } else {
      mouseOn = 1;
      phone.subscribeAttitude(60);
    }
  }
}

void onTouchEvent(String ipAddress, int x,int y) {
  
  tDown = 0;
  if (mouseOn == 1) {
    if (x < m1) {
      rbt.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
    }
    if (x > m2) {
      rbt.mousePress(InputEvent.BUTTON3_DOWN_MASK);
      rbt.mouseRelease(InputEvent.BUTTON3_DOWN_MASK);
    }
    
    phone.setBrightness(0.5);
    phone.showImage("https://cdn.discordapp.com/attachments/507959773287677954/677601357166936077/Mouse_Mouse.png");
  } else {
    phone.setBrightness(0.1);
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
