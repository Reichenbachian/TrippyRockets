//Creds: http://www.i2cdevlib.com/forums/topic/113-mpu6050-dmp-sketch-hangs-sometimes/ //<>//
//Creds: http://cdn.akamai.steamstatic.com/steam/apps/289760/header.jpg?t=1447361012
//Both were used to stop arduino from hanging
class PlayerRocket extends Rocket {
  private static final boolean DEBUG_PLAYER = false;
  private static final float BULLET_COOLDOWN = 200;
  private static final int IMU_BUFFER = 5;
  private boolean imuControlled;
  private boolean initialZero;

  MovingAverage yaw;
  MovingAverage pitch;
  MovingAverage roll;

  /**
   * Constructs a rocket at given x and y coordinate. Also sets if this
   * rocket is being controlled by IMU.
   */
  public PlayerRocket(float xPos, float yPos, boolean imuControlled, 
    Iterator<Rocket> rocketIter) {
    super(xPos, yPos, true, rocketIter);

    this.imuControlled = imuControlled;
    if (DEBUG_PLAYER) {
      // List all the available serial ports:
      System.out.println(String.join("", Serial.list()));
    }
    yaw = new MovingAverage(IMU_BUFFER);
    pitch = new MovingAverage(IMU_BUFFER);
    roll = new MovingAverage(IMU_BUFFER);
    initialZero = false;
  }

  /**
   * Loads the player rocket image(the yellow one.)
   */
  public void loadRocketImage() {
    super.img = loadImage("player.png");
  }

  /**
   * Updates the position of the player, if IMU_MODE is set to true,
   * updates by pitch and roll average.
   */
  public boolean update() {
    //If roll is full, they all are.
    //Wait for initial zero
    if (roll.isFull() && !initialZero) {
      initialZero = true;
      zeroIMU();
    }
    //Wait until zeroed before moving
    if (Final.IMU_MODE && imuControlled && !roll.isFull()) {
      return true;
    }
    float accelRatio = pitch.getAverage()/roll.getAverage(); 
    float rotGoal = atan(accelRatio);
    //Deal with inverse tangent range
    if ((pitch.getAverage() > 0 && roll.getAverage() > 0)) {
      rotGoal += PI;
    } else if (pitch.getAverage() < 0 && roll.getAverage() > 0) {
      rotGoal+=PI;
    }
    if (rotGoal > -1000) {
      super.rot = rotGoal;
    }
    return super.update();
  }

  /**
   * Handles the keyStroke data passed to it.
   * Up,down,left,right arrow key -> first player(unless overridden by IMU)
   * "wasd" -> second player.
   */
  public void keyStroke(boolean[] keys, boolean playerOne) {
    if ((keys[9] && playerOne) || (keys[4] && !playerOne)) {
      super.shoot();
    } else if ((keys[8] && playerOne) || (keys[3] && !playerOne)) {
      //Right
      super.setRotAccel(super.getRotAccel()+Rocket.ROT_SPEED);
    } else if ((keys[7] && playerOne) || (keys[1] && !playerOne)) {
      //Left
      super.setRotAccel(super.getRotAccel()-Rocket.ROT_SPEED);
    } else if ((keys[5] && playerOne) || (keys[0] && !playerOne)) {
      //Up
      super.accel(Rocket.ACCEL_SPEED);
    } else if ((keys[6] && playerOne) || (keys[2] && !playerOne)) {
      //Down
      super.accel(-Rocket.ACCEL_SPEED);
    }
  }

  /**
   * Communicates with the arduino, handeling all
   * the edge cases I've ran in to.(Which there are a lot of.)
   */
  boolean handleSerielEvent(Serial myPort) {
    //Sample packet: #144.41<-62.18>-15.12@N%N*$
    try {
      String received = myPort.readString();

      //Make sure packet is valid.
      if (received == null || received.length() > 0 && !received.contains("#") ||
        !received.contains("$") || !received.contains("<") ||
        !received.contains(">") || !received.contains("%") ||
        !received.contains("*") || !received.contains("@")) {
        System.out.println("Malformed packet!!: " + received);
        return false;
      }
      //Offset instead of absolute because packets sometimes are slightly corrupted, but repairable
      received = received.substring(received.indexOf("#")+1, 
        received.indexOf("$"));
      String yawString = received.substring(0, 
        received.indexOf("<"));
      String pitchString = received.substring(received.indexOf("<")+1, 
        received.indexOf(">"));
      String rollString = received.substring(received.indexOf(">")+1, 
        received.indexOf("@"));
      String accelerate = received.substring(received.indexOf("@")+1, 
        received.indexOf("%"));
      String shoot = received.substring(received.indexOf("%")+1, 
        received.indexOf("*"));
      try {
        yaw.add(Float.parseFloat(yawString));
        pitch.add(-Float.parseFloat(pitchString));
        roll.add(Float.parseFloat(rollString));
      } 
      catch (NumberFormatException e) {
        System.out.println("Malformed packet!!: " + received);
      }
      if (shoot.equals("Y")) {
        super.shoot();
      }
      if (accelerate.equals("Y")) {
        super.yAccel-=cos(super.rot)*Rocket.ACCEL_SPEED*Rocket.IMU_ACCEL_ADVANTAGE;
        super.xAccel-=sin(super.rot)*Rocket.ACCEL_SPEED*Rocket.IMU_ACCEL_ADVANTAGE;
      }
    } 
    catch (RuntimeException e) {
      e.printStackTrace(System.out);
    }
    return false;
  }

  public String data() {
    return "Yaw: " + Math.round((float)yaw.getAverage()) + " Pitch: " +
      Math.round((float)pitch.getAverage()) + "\n\tRoll: " + Math.round((float)roll.getAverage());
  }


  /**
   * Updates image, if exploding and done with last frame, 
   * returns a boolean in order to overload the rocket method.
   */
  public boolean exploding() {
    if (super.currentlyExploding) {
      super.img = explosion.update(millis());
    }
    if (super.img == null) {
      super.img = explosion.reset();
      zero();
      super.currentlyExploding = false;
    }
    return true;
  }

  /**
   * Returns cooldown. Not constant because
   * AI overrides it.
   */
  public float getCooldown() {
    return BULLET_COOLDOWN;
  }

  /**
   * Zeroes IMU.
   */
  public void zeroIMU() {
    if (imuControlled) {
      roll.zero();
      pitch.zero();
      yaw.zero();
    }
  }
}