/*
 * Crazy Rockets
 * By: Alex Reichenbach
 * Date: May 31, 2016
 * Dr. Miles 2nd Period Compsci 500.
 */
//Creds to Thomas for and Buzzy for helping by playing
import java.util.List;
import java.util.ArrayList;
import ddf.minim.*;
import java.util.Iterator;
import ddf.minim.analysis.*;
import processing.opengl.*;

private static final boolean DEBUG_MAIN = false;
private static final boolean DEBUG_ROCKET = false;
private static final int TOP_BAR_SIZE = 60;
private static final int FRAME_RATE_BUFFER = 10;
private static final int BACKGROUND_RGB[] = {0, 2, 10};
//true if startScreen should be shown
private static boolean startScreen = true;
private static boolean IMU_MODE = false;
//Required to be created in this thread. Used in other files,
//therefore I made it "Global"
Minim minim = new Minim(this);
/* 0: W
 * 1: A
 * 2: S
 * 3: D
 * 4: E
 * 5: UP
 * 6: DOWN
 * 7: LEFT
 * 8: RIGHT
 * 9: SPACE
 */
//An array of all the buttons. Used mostly because of multiplayer.
private boolean[] keys;
/*
* True: Normal
 * False: Survival
 */

private static boolean normalMode = true;

float imuBottonPos;
float addPlayerButtonPos;
float addAIButtonPos;
float zeroIMU;
float resetButtonPos;
float switchGameButtonPos;
//Screen is broken into 14ths to allow auto-formating
//It's the one magic value so the rest don't have to be.
float distBetweenButtons = 2;
float buttonWidth = (width*1/14)-distBetweenButtons;
float distanceFromTop = TOP_BAR_SIZE*.5;

//Moving average of the frame rate keeps it from quickly flickering
//and becoming distracting
MovingAverage frameRateAverage;

PFont labelFont;
PImage img;
PShape model;
Serial serial;
Game game;

/**
 * Program setup. Creates screen and initializes variables and serial.
 */
void setup() {
  size(1200, 740, P3D);
  //Allow resizing of screen
  surface.setResizable(true);
  frameRateAverage = new MovingAverage(FRAME_RATE_BUFFER);
  labelFont = createFont("luxirr.ttf", 40);
  keys = new boolean[10];
  game = new NormalGameplay();
}

/**
 * Draws the game data, the frame rate, and the timer. 
 */
public void drawTopLabels() {
  textAlign(LEFT);
  fill(255);
  textFont(labelFont, 15);
  //Updates labels on screen with their respective moving averages.
  text(game.data(), 10, 20);
  frameRateAverage.add(frameRate);
  text("Frame rate: " + round((float)frameRateAverage.getAverage()), 
    width*(5.0/6), 20);
  textFont(labelFont, 40);
  text(game.header(), width*.5, 45);
  textFont(labelFont, 15);
}

/**
 * Draws the buttons. The top screen is broken up into 14ths, to allow
 * resizing. The numerators of the fraction represent the positions.
 */
public void drawTopSettings() {
  noStroke();
  //Reload each time in case of screen size change.
  textAlign(CENTER);
  textFont(labelFont, 10);
  resetButtonPos = width*8.5/14+distBetweenButtons;
  buttonWidth = (width*1/14)-distBetweenButtons; 
  imuBottonPos = (width*2/14)-distBetweenButtons; 
  switchGameButtonPos = width*9.5/14+distBetweenButtons;
  zeroIMU = width*5/14+distBetweenButtons;
  resetButtonPos = width*8.5/14+distBetweenButtons;
  switchGameButtonPos = width*9.5/14+distBetweenButtons;
  fill(196);
  rect(switchGameButtonPos, 5, buttonWidth, distanceFromTop);
  //Only draw player adding buttons if in normal mode
  if (normalMode) {
    addPlayerButtonPos = width*3/14+distBetweenButtons;
    addAIButtonPos = width*4/14+distBetweenButtons;
    rect(addPlayerButtonPos, 5, buttonWidth, distanceFromTop);
    rect(addAIButtonPos, 5, buttonWidth, distanceFromTop);
    fill(0);
    text("Add\nPlayer", addPlayerButtonPos+buttonWidth/2, distanceFromTop/2);
    text("Add\nComputer", addAIButtonPos+buttonWidth/2, distanceFromTop/2);
    text("Survival", switchGameButtonPos+buttonWidth/2, distanceFromTop*(4.0/5));
  } else {
    fill(0);
    text("Normal\nMode", switchGameButtonPos+buttonWidth/2, distanceFromTop/2);
  }
  fill(196);
  rect(imuBottonPos, 5, buttonWidth, distanceFromTop);
  rect(resetButtonPos, 5, buttonWidth, distanceFromTop);
  rect(zeroIMU, 5, buttonWidth, distanceFromTop);
  fill(0);
  text("Zero\nController", zeroIMU+buttonWidth/2, distanceFromTop/2);
  text("Reset\nGame", resetButtonPos+buttonWidth/2, distanceFromTop/2);
  if (IMU_MODE) {
    text("End\nController", imuBottonPos+buttonWidth/2, distanceFromTop/2);
  } else {
    text("Start\nController", imuBottonPos+buttonWidth/2, distanceFromTop/2);
  }
}

/**
 * Program loop.
 */
void draw() {
  background(BACKGROUND_RGB[0], BACKGROUND_RGB[1], BACKGROUND_RGB[2]);
  if (startScreen) {
    fill(255);
    textFont(labelFont, 30);
    text("Arrow Keys and space bar for first player.\nWASD and E for the second player.", 
      width/2, height/2);
  }
  drawTopLabels();
  drawTopSettings();
  //Deal with the potentially multiple keypresses
  for (int i = 0; i < keys.length; i++) {
    game.handleKeys(keys);
  }
  game.draw();
}

//==============================================================================
// USER INPUT
//==============================================================================

/**
 * Removes startscreen and changes the keys array to reflect input
 */
void keyPressed() {
  startScreen = false;
  invertKey(keyCode);
}

/**
 * Changes the keys array to reflect input
 */
void keyReleased() {
  invertKey(keyCode);
}

/**
 * Inverts given key in keys array
 */
void invertKey(int daKey) {
  if (daKey == 32) {
    //Space
    keys[9] = !keys[9];
  } else if (daKey == 16) {
    //Shift
    keys[4] = !keys[4];
  } else if (daKey == 39) {
    //Right
    keys[8] = !keys[8];
  } else if (daKey == 68) {
    //D
    keys[3] = !keys[3];
  } else if (daKey == 37) {
    //Left
    keys[7] = !keys[7];
  } else if (daKey == 65) {
    //A
    keys[1] = !keys[1];
  } else if (daKey == 38) {
    //Up
    keys[5] = !keys[5];
  } else if (daKey == 87) {
    //W
    keys[0] = !keys[0];
  } else if (daKey == 40) {
    //Down
    keys[6] = !keys[6];
  } else if (daKey == 83) {
    //S
    keys[2] = !keys[2];
  }
}

/**
 * Handles button input from top
 */
public void mousePressed() {
  startScreen = false;
  //Only react if in top bar
  if (mouseY < TOP_BAR_SIZE) {
    if (normalMode) {
      //If normal mode
      if (mouseX > addPlayerButtonPos &&
        mouseX < addPlayerButtonPos+buttonWidth) {
        game.addPlayer();
      } else if (mouseX > addAIButtonPos &&
        mouseX < addAIButtonPos+buttonWidth) {
        game.addAIPlayer();
      } else if (mouseX > switchGameButtonPos &&
        mouseX < switchGameButtonPos+buttonWidth) {
        game.stopAudio();
        game = new Survival();
        normalMode = !normalMode;
      } else if (mouseX > resetButtonPos &&
        mouseX < resetButtonPos+buttonWidth) {
        game.stopAudio();
        startScreen = true;
        game = new NormalGameplay();
      }
    } else {
      if (mouseX > switchGameButtonPos &&
        mouseX < switchGameButtonPos+buttonWidth) {
        game.stopAudio();
        game = new NormalGameplay();
        normalMode = !normalMode;
      } else if (mouseX > resetButtonPos &&
        mouseX < resetButtonPos+buttonWidth) {
        game.stopAudio();
        startScreen = true;
        game = new Survival();
      }
    }
    if (IMU_MODE && mouseX > zeroIMU && mouseX < zeroIMU+buttonWidth) {
      game.zeroPlayer();
    }
    if (mouseX > imuBottonPos && mouseX < imuBottonPos+buttonWidth) {
      if (!IMU_MODE) {
        createSerial();
      } else {
        System.out.println("Closed Serial");
        if (serial != null) {
          serial.stop();
        }
      }
      IMU_MODE = !IMU_MODE;
      if (normalMode) {
        game = new NormalGameplay();
      } else {
        game = new Survival();
      }
    }
  }
}

/**
 * Creates a serial connection with best guess of controller attached.
 */
public void createSerial() {
  System.out.println("Started Serial with best guess");
  String[] serialList = Serial.list();
  String port = "";
  for (int i = 0; i < serialList.length; i++) {
    if (serialList[i].contains("tty.usbmodem")) {
      port = serialList[i];
      break;
    }
  }
  if (!port.equals("")) {
    serial = new Serial(this, serialList[1], 230400);
    serial.bufferUntil('$');
  } else {
    System.out.println("NO USB ATTATCHED!");
  }
}

/**
 * Handles the serial events, but only if IMU_MODE is set to true.
 */
public void serialEvent(Serial myPort) {
  try {
    if (IMU_MODE) {
      game.handleSerial(myPort);
    }
  } 
  catch(RuntimeException e) {
    e.printStackTrace();
  }
}

public class Point {
  float xPos;
  float yPos;
}