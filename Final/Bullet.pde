/**
 * Represents a bullet.
 */
private class Bullet {
  public float xPos;
  public float yPos;
  public float rot;
  private final static float BULLET_SPEED = 10;
  private final static int BULLET_WIDTH = 2;
  private final static int BULLET_HEIGHT = 2;

  /**
   * Constructs a bullet.
   */
  public Bullet(float xPos, float yPos, float rot) {
    //Shoot in front so you don't blow up yourself
    this.xPos = xPos + 1.5*sin(rot)*Rocket.ROCKET_WIDTH/2;
    this.yPos = yPos - 1.5*cos(rot)*Rocket.ROCKET_HEIGHT/2;
    this.rot = rot;
  }

  /**
   * Draws the bullet.
   */
  public void draw() {
    stroke(0, 255, 0);
    rect(xPos, yPos, BULLET_WIDTH, BULLET_HEIGHT);
  }

  /**
   * Updates the bullets position and returns false if bullet should be deleted.
   */
  public boolean update() {
    if (xPos - 20 > width || xPos + 20 < 0
      || yPos - 20 > height || yPos + 20 < 0) {
      return false;
    }
    xPos += sin(rot)*BULLET_SPEED;
    yPos -= cos(rot)*BULLET_SPEED;
    return true;
  }
}