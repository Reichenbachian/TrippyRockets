//Creds: https://sebastiencourtois.files.wordpress.com/2011/08/explosion.png
//for the explosion animation.
/**
 * Abstract rocket representation.
 */
abstract class Rocket {
  private float xPos;
  private float yPos;
  private float xAccel;
  private float yAccel;
  private float rot;
  private float rotAccel;
  private PImage img;
  private float previousShootTime;
  private int deaths;
  private int rocketID;
  private boolean showLabel;

  Animation explosion;
  private boolean currentlyExploding;
  public static final int ROCKET_WIDTH = 30;
  public static final int ROCKET_HEIGHT = 45;
  private static final float ROT_SPEED = .0002;
  private static final float ACCEL_SPEED = .02;
  private static final int MAX_SPEED = 8;
  private static final float MAX_ACCEL = 1;
  private static final float MAX_ROT_ACCEL = .01;
  private static final float SPAWN_SIDE_BUFFER = 100;
  private static final float IMU_ACCEL_ADVANTAGE = 2;
  private static final float ROCKET_CHARGE_SPEED = 1.5;

  /**
   * Returns data of rocket. Usually called for IMU rocket
   */
  abstract String data();
  abstract float getCooldown();

  /**
   * Constructs a rocket at given x and y position.
   */
  public Rocket(float xPos, float yPos, boolean showLabel, Iterator<Rocket> rocketIter) {
    this.showLabel = showLabel;
    if (xPos == -1 && yPos == -1) {
      //BUGBUG: Assumes there is a place to put rocket
      while (xPos == -1 && yPos ==-1 && !this.checkRocketCollision(rocketIter, false)) {
        //Get valid x spawn spot
        xPos = random(width-SPAWN_SIDE_BUFFER)+SPAWN_SIDE_BUFFER/2;
        yPos = random(height-SPAWN_SIDE_BUFFER-Final.TOP_BAR_SIZE)+
          (SPAWN_SIDE_BUFFER+Final.TOP_BAR_SIZE)/2;
      }
    }
    this.xPos = xPos;
    this.yPos = yPos;
    this.previousShootTime = 0;
    this.currentlyExploding = false;
    loadRocketImage();
    //Creds for grenade sound: https://www.freesound.org/people/qubodup/sounds/162363/
    explosion = new Animation("explosion/", 12, (int)frameRate, img, "Grenade.wav");
    //BUGBUG: Collisions are possible, however, very unlikely.
    rocketID = (int)random(Integer.MAX_VALUE);
  }


  /**
   *  Chooses an rocket image from the 2 enemy ones.
   */
  public void loadRocketImage() {
    if (random(2)>1) {
      img = loadImage("Enemy1.png");
    } else {
      img = loadImage("Enemy2.png");
    }
  }

  /**
   * Updates the rocket. Returns true if the rocket is currently
   * exploding.
   */
  public boolean update() {
    xAccel = Math.min(xAccel, MAX_SPEED);
    yAccel = Math.min(yAccel, MAX_SPEED);
    xPos -= xAccel;
    yPos += yAccel;
    rot += rotAccel;
    rot %= TWO_PI;
    //Check if in screen bounds
    if (yPos < 0 || yPos > height) {
     explode();
    } else if (xPos < 0 || xPos > width) {
      //Flip to other side of screen.
     xPos = width-xPos;
    }
    if (showLabel) {
      fill(255);
      textFont(labelFont, 13);
      text(deaths, xPos, yPos-.75*ROCKET_HEIGHT);
    }
    //Also updates frame if necessary
    return exploding();
  }

  /**
   * Returns whether the rocket is currenly exploding
   * and updates the frame if it is.
   */
  public boolean exploding() {
    if (currentlyExploding) {
      img = explosion.update(millis());
    }
    return img == null;
  }

  /**
   * Draws the rocket onto the screen
   */
  public void draw() {
    //Moves to origin, rotates, moves back.
    //Otherwise rotates about origin.
    if (img != null) {
      fill(Final.BACKGROUND_RGB[0], Final.BACKGROUND_RGB[1], Final.BACKGROUND_RGB[2]);
      noStroke();
      imageMode(CENTER);
      translate(xPos, yPos);
      rotate(rot);
      image(img, 0, 0, ROCKET_WIDTH, ROCKET_HEIGHT);
      rotate(-rot);
      translate(-xPos, -yPos);
    } else {
      System.out.println("ROCKET IMAGE IS NULL!");
    }
  }

  /**
   * Resets rockets to original positions.
   */
  public void zero() {
    this.xPos = random(width-SPAWN_SIDE_BUFFER)+SPAWN_SIDE_BUFFER/2;
    this.yPos = random(height-SPAWN_SIDE_BUFFER-Final.TOP_BAR_SIZE)+(SPAWN_SIDE_BUFFER+Final.TOP_BAR_SIZE)/2;
    this.rot = 0;
    this.rotAccel = 0;
    this.xAccel = 0;
    this.yAccel = 0;
  }

  /**
   * Çreates a bullet and calls Game's shoot method.
   */
  public void shoot() {
    shootWithOffset(0);
  }

  /**
   * Shoots with offset. Offset is used by AI rocket to reduce accuracy
   */
  public void shootWithOffset(float offset) {
    if (!currentlyExploding && previousShootTime + getCooldown() < millis()) {
      if (Final.DEBUG_ROCKET) {
        println("Created bullet at: " + " xPos:" + xPos + " yPos:" + yPos);
      }
      previousShootTime = millis();
      game.shoot(xPos, yPos, rot+offset);
    }
  }

  /**
   * Starts animation and sets endTime.
   */
  public void explode() {
    if (!currentlyExploding) {
      deaths++;
    }
    currentlyExploding = true;
  }

  /**
   * Returns x coordinates of intersection of line and ellipse.
   * Returns null if none.
   */
  public float[] ovalLineIntersect(float lineX1, float lineY1, float lineX2, float lineY2, float xPos, float yPos) {
    float retArr[] = new float[2];
    float a = ROCKET_WIDTH/2;
    float b = ROCKET_HEIGHT/2;
    float m = (lineY2-lineY1)/(lineX2-lineX1);
    float c = -m*lineX2+lineY2;
    float cPlusMH = c+m*xPos;
    float cMinusK = c-yPos;
    float preSquareRoot = a*a*m*m+b*b-cPlusMH*cPlusMH-yPos*yPos+2*cPlusMH*yPos;
    if (preSquareRoot < 0) {
      return null;
    }
    float doubleAdoubleMPlusB = a*a*m*m+b*b;
    float postSquareRootOver = (a*b*(float)Math.sqrt(preSquareRoot))/(doubleAdoubleMPlusB);
    float prePlusOrMinus = (xPos*b*b-m*a*a*cMinusK)/(doubleAdoubleMPlusB);
    retArr[0] = prePlusOrMinus-postSquareRootOver;
    retArr[1] = prePlusOrMinus+postSquareRootOver;
    return retArr;
  }

  /**
   * Checks if values of intersection are within the bounds.
   */
  public boolean checkXBounds(float[] xIntersectVal, float x1Bound, float x2Bound) {
    return (xIntersectVal != null) &&
      ((xIntersectVal[0] >= x1Bound && xIntersectVal[0] <= x2Bound) ||
      (xIntersectVal[1] >= x1Bound && xIntersectVal[1] <= x2Bound) ||
      (xIntersectVal[0] <= x1Bound && xIntersectVal[1] >= x2Bound));
  }

  /**
   * Checks if this rocket collides with bar. 
   */
  public void checkBarCollision(float barXCoord, float r_width, float barHeight) {
    if (barHeight < 0) {
      barHeight = -barHeight;
    }
    if (barHeight > height-yPos) {
      barHeight = height-yPos;
    }
    float xIntersectVal[] = ovalLineIntersect(0, barHeight, 1, barHeight, xPos, height-yPos);
    if (checkXBounds(xIntersectVal, barXCoord, barXCoord+r_width)) {
      explode();
    }
  }

  /**
   * Checks if this line collides with this rocket.
   */
  public boolean checkLineCollision(float x1, float y1, float x2, float y2) {
    float xIntersectVal[] = ovalLineIntersect(x1, y1, x2, y2, xPos, yPos);
    return checkXBounds(xIntersectVal, x1, x2);
  }

  /**
   * Treating bullet as point because the trig isn't worth it.
   */
  public void checkBulletCollision(List<Bullet>bullets) {
    for (Bullet bullet : bullets) {
      if ((xPos-bullet.xPos)*(xPos-bullet.xPos)/(ROCKET_WIDTH*ROCKET_WIDTH/4)
        + (yPos-bullet.yPos)*(yPos-bullet.yPos)/(ROCKET_HEIGHT*ROCKET_HEIGHT/4)<=1) {
        explode();
      }
    }
  }

  /**
   * Check rocket collision
   */
  //Creds to thomas for idea of using definition of ellipse, though I did think of the rest
  //and implement it.
  public boolean checkRocketCollision(Iterator<Rocket> rocketIter, boolean explodeIfColiding) {
    while (rocketIter.hasNext()) {
      Rocket rocket = rocketIter.next();
      //If the distance from the midpoint to the foci added together is
      //less than the ellipse's distance, as by the definition of an ellipse,
      //it is overlapping, and thus should explode both.
      int aS = ROCKET_WIDTH*ROCKET_WIDTH/4;
      int bS = ROCKET_HEIGHT*ROCKET_HEIGHT/4;
      float cValue = (float)Math.sqrt(Math.abs(aS-bS));
      Point foci1 = new Point();
      Point foci2 = new Point();
      Point midPoint = new Point();
      foci1.xPos = this.xPos + cos(this.rot+PI/2)*cValue;
      foci1.yPos = this.yPos + sin(this.rot+PI/2)*cValue;
      foci2.xPos = this.xPos - cos(this.rot+PI/2)*cValue;
      foci2.yPos = this.yPos - sin(this.rot+PI/2)*cValue;
      midPoint.xPos = (this.xPos + rocket.getX())/2;
      midPoint.yPos = (this.yPos + rocket.getY())/2;
      float thisDistance = (float)(ROCKET_HEIGHT);
      //Allowed to only calculate for one rocket since all
      //rockets are the same size.
      float fociOneDist =
        (float)Math.sqrt((foci1.xPos-midPoint.xPos)*(foci1.xPos-midPoint.xPos) +
        (foci1.yPos-midPoint.yPos)*(foci1.yPos-midPoint.yPos));
      float fociTwoDist =
        (float)Math.sqrt((foci2.xPos-midPoint.xPos)*(foci2.xPos-midPoint.xPos) +
        (foci2.yPos-midPoint.yPos)*(foci2.yPos-midPoint.yPos));
      if (fociOneDist + fociTwoDist < thisDistance
        && rocket.getID() != this.getID()) {
        if (explodeIfColiding) {
          rocket.explode();
          this.explode();
        } else {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Returns deaths.
   */
  public int getDeaths() {
    return deaths;
  }

  /**
   * Sets the rotation acceleration
   */
  public void setRotAccel(float rotAccel) {
    this.rotAccel = rotAccel;
  }

  /**
   * Gets the rotation acceleration
   */
  public float getRotAccel() {
    return this.rotAccel;
  }

  /**
   * Gets the rotation
   */
  public float getRot() {
    return this.rot;
  }

  /**
   * Sets the acceleration
   */
  public void accel(float accel) {
    this.yAccel-=cos(this.rot)*accel;
    this.xAccel-=sin(this.rot)*accel;
  }

  /**
   * Gets the x position
   */
  public float getX () {
    return xPos;
  }

  /**
   * Gets the y position
   */
  public float getY () {
    return yPos;
  }

  /**
   * Gets rocket id
   */
  public float getID () {
    return rocketID;
  }
}