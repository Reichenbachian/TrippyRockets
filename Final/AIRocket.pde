/**
 *  Represents an AIRocket that is a hardcoded one written by me.
 */
class AIRocket extends Rocket {
  private static final float BULLET_COOLDOWN = 800;
  private static final float ACCURACY = .7;
  private static final float EDGE_BUFFER_TENDENCY = 300;


  /**
   * Constructs an AIRocket.
   */
  public AIRocket(float xPos, float yPos, Iterator<Rocket> rocketIter) {
    //Has to be done in one line.
    super(xPos, yPos, false, rocketIter);
  }

  /**
   * Updates AI position based on location of bullets and other rockets. Can't be in
   * normal update method because it requires extra information that can't be accessed
   * like the rocket iterator.
   */
  public void aiUpdate(List<Bullet> bullets, Iterator<Rocket> rocketIter) {
    boolean shoot = false;
    double accelChange = 0;
    double rotChange = 0;
    //Avoid bullets
    for (Bullet bullet : bullets) {
      //checkLineCollision requires two points, so extrapolate
      //two other points assuming straight line.
      float predictedX = bullet.xPos+sin(PI-bullet.rot)*Bullet.BULLET_SPEED;
      float predictedY = bullet.yPos+cos(PI-bullet.rot)*Bullet.BULLET_SPEED;
      float[] intersect = ovalLineIntersect(bullet.xPos, bullet.yPos, 
        predictedX, predictedY, super.xPos, super.yPos);
      if (intersect != null &&
        ((bullet.xPos < predictedX && super.xPos > bullet.xPos)
        || (bullet.xPos > predictedX && super.xPos < bullet.xPos))) {
        //Run run!
        accelChange += random(Rocket.MAX_ACCEL/2);
      }
    }
    float predictedX = super.xPos+sin(PI-super.rot)*Bullet.BULLET_SPEED;
    float predictedY = super.yPos+cos(PI-super.rot)*Bullet.BULLET_SPEED;
    //Aim at other rockets and shoot
    Rocket nearestRocket = null;
    double smallestDistance = Double.POSITIVE_INFINITY;
    while (rocketIter.hasNext()) {
      Rocket rocket = rocketIter.next();
      if (rocket.rocketID == super.rocketID) {
        continue;
      }
      double checkDistance = Math.sqrt((rocket.xPos - super.xPos)*
        (rocket.xPos - super.xPos)+(rocket.yPos - super.yPos));
      if (checkDistance < smallestDistance) {
        nearestRocket = rocket;
        smallestDistance = checkDistance;
      }
      float[] intersect = ovalLineIntersect(super.xPos, super.yPos, 
        predictedX, predictedY, rocket.xPos, rocket.yPos);
      //Fire away captain!
      if (intersect != null &&
        ((rocket.xPos < predictedX && super.xPos > rocket.xPos)
        || (rocket.xPos > predictedX && super.xPos < rocket.xPos))) {
        shoot = true;
      }
    }

    float thetaGoal = super.rot;
    //Aim at nearest rocket
    if (nearestRocket != null && rotChange == 0) {
      float deltaY = super.yPos-nearestRocket.yPos;
      float deltaX = nearestRocket.xPos-super.xPos;
      thetaGoal = -(atan(deltaY/deltaX)+PI/2)%TWO_PI;
      //Account for range of inverse tangent
      if (deltaX>0) {
        thetaGoal+=PI;
      }
    }

    //Update rotation towards rotation goal.
    if (thetaGoal < super.rot) {
      rotChange-=Rocket.MAX_ROT_ACCEL/1.5;
    } else {
      rotChange+=Rocket.MAX_ROT_ACCEL/1.5;
    }

    if (rotChange == 0) {
      super.rotAccel/=1.2;
    }
    super.rot += rotChange;
    super.accel((float)accelChange);
    if (shoot) {
      super.shootWithOffset(random(ACCURACY)-.5*ACCURACY);
      if (super.rocketID%5 == 0) {
        accelChange += Rocket.ROCKET_CHARGE_SPEED;
      }
    }
    if (accelChange == 0) {
      super.xAccel/=1.2;
      super.yAccel/=1.2;
    }
  }

  /**
   * Updates AI position and checks if in bounds
   */
  public boolean update() {
    if (super.xPos < 0 || super.xPos > width) {
      super.explode();
    }
    return super.update();
  }

  /**
   * No data available for AIRocket, so return empty string
   */
  public String data() {
    return "";
  }

  /**
   * Returns the cooldown of this instance of a rocket.
   */
  public float getCooldown() {
    return BULLET_COOLDOWN;
  }
}