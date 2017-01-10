/**
 * Abstract class the represents a rockets game. 
 */
abstract class Game {
  //INVARIANT:
  //Players can only contain 2 rockets at most
  private List<Bullet> bullets;
  private List<AIRocket> aiRockets;
  //It is a list to maintain consistancy with other lists.
  private List<PlayerRocket> players;
  private Background background;

  /**
   * Returns game data such as level or imu data
   */
  public abstract String data();
  /**
   * Returns the games header. Main string in top middle.
   */
  public abstract String header();
  /**
   * Resets the game.
   */
  public abstract void reset();

  /**
   * Handles the serial event by passing it to first rocket.
   */
  public void handleSerial(Serial serial) {
    if (players.size() > 0) {
      players.get(0).handleSerielEvent(serial);
    }
  }
  /**
   * Handles the key stroke by passing it to respective rocket.
   */
  public void handleKeys(boolean[] keys) {
    //Send keys to all player rockets on screen
    if (players.size() > 1) {
      players.get(1).keyStroke(keys, false);
    } 
    if (players.size() > 0) {
      players.get(0).keyStroke(keys, true);
    }
  }

  /**
   * Calls initializeArrays(), which needs to be seperate so it can be
   * called by reset.
   */
  public Game() {
    initializeArrays();
    //Backrgound must be initialized after game
    background = new Background(width/2, height/2);
  }

  /**
   * Initializes arrays. Called by subclasses.
   */
  public void initializeArrays() {
    bullets = new ArrayList<Bullet>();
    aiRockets = new ArrayList<AIRocket>();
    players = new ArrayList<PlayerRocket>();
  }

  /**
   * Adds a bullet to the array, which shall be shot.
   */
  public void shoot(float xPos, float yPos, float rot) {
    bullets.add(new Bullet(xPos, yPos, rot));
  } 

  /**
   * Checks for collision with bottom visualizer
   */
  public void checkCollisionTopVisualizer(float x1, float y1, float x2, float y2) {
    //Enemies
    Iterator<Rocket> rocketIter = rocketIterator();
    while (rocketIter.hasNext()) {
      Rocket rocket = rocketIter.next();
      if (rocket.checkLineCollision(x1, y1, x2, y2)) {
        rocket.explode();
      }
    }
  }

  /**
   * Checks for collision with top visualizer
   */
  public void checkCollisionBottomVisualizer(float barXCoord, float r_width, float barHeight) {
    //Enemies
    Iterator<Rocket> rocketIter = rocketIterator();
    while (rocketIter.hasNext()) {
      Rocket rocket = rocketIter.next();
      rocket.checkBarCollision(barXCoord, r_width, barHeight);
    }
  }

  /**
   * Checks for collision with a bullet
   */
  public void checkBulletHit() {
    Iterator<Rocket> rocketIter = rocketIterator();
    while (rocketIter.hasNext()) {
      Rocket rocket = rocketIter.next();
      rocket.checkBulletCollision(bullets);
    }
  }

  /**
   * Stops the audio
   */
  public void stopAudio() {
    background.stopAudio();
  }

  /**
   * Checks for collision with a rocket
   */
  public void checkRocketCollision() {
    Iterator<Rocket> rocketIter = rocketIterator();
    while (rocketIter.hasNext()) {
      Rocket rocket = rocketIter.next();
      rocket.checkRocketCollision(rocketIterator(), true);
    }
  }

  /**
   * Update and draw the bullet position.
   */
  public void updateBullets() {
    //Draw bullets, counting backwards to allow deleting
    for (int i = bullets.size()-1; i >= 0; i--) {
      //If bullet failed to udpate, delete it
      if (!bullets.get(i).update()) {
        if (Final.DEBUG_MAIN) {
          println("Deleted bullet at index: " + i + " xPos:" +
            bullets.get(i).xPos + " yPos:" + bullets.get(i).yPos);
        }
        bullets.remove(i);
      } else {
        bullets.get(i).draw();
      }
    }
  }

  /**
   * Updates and draws the AI positions.
   */
  public void updateAI() {
    //Draw and update the rockets
    for (int i = aiRockets.size()-1; i>=0; i--) {
      aiRockets.get(i).aiUpdate(bullets, rocketIterator());
      if (aiRockets.get(i).update()) {
        aiRockets.remove(i);
        continue;
      }
      aiRockets.get(i).draw();
    }
  }

  /**
   * Draws the game.
   */
  public void draw() {
    int playerOneX = Integer.MIN_VALUE;
    int playerOneY = Integer.MIN_VALUE;
    int playerTwoX = Integer.MIN_VALUE;
    int playerTwoY = Integer.MIN_VALUE;
    if (players.size() >= 2) {
      playerTwoX = (int)players.get(1).getX();
      playerTwoY = (int)players.get(1).getY();
    }
    if (players.size() >= 1) {
      playerOneX = (int)players.get(0).getX();
      playerOneY = (int)players.get(0).getY();
    }
    background.update(playerOneX, playerOneY, playerTwoX, playerTwoY);
    updateBullets();
    updateAI();
    for (int i = 0; i < players.size(); i++) {
      players.get(i).update();
      players.get(i).draw();
    }
    checkBulletHit();
    checkRocketCollision();
  }

  /**
   * Adds ai player.
   */
  public void addAIPlayer() {
    aiRockets.add(new AIRocket(-1, -1, rocketIterator()));
  }

  /**
   * Adds human player, no-op if already 2 rockets
   */
  public void addPlayer() {
    if (players.size() < 2) {
      //Set imu to true if activated and player is first
      players.add(new PlayerRocket(-1, -1, players.size()==0 &&
        Final.IMU_MODE, rocketIterator()));
    }
  }

  /**
   * Zeroes player if one is present.
   */
  public void zeroPlayer() {
    if (players.size() > 0) {
      players.get(0).zeroIMU();
    }
  }

  /**
   * Returns a rocket iterator
   */
  public Iterator<Rocket> rocketIterator() {
    return new RocketIterator();
  }

  /**
   * An iterator through all rockets
   */
  private class RocketIterator implements Iterator<Rocket> {
    private int current;

    public boolean hasNext() {
      return current < (aiRockets.size()+players.size());
    }

    public Rocket next() {
      if (current < players.size()) {
        return players.get(current++);
      }
      if (current < aiRockets.size()+players.size()) {
        return aiRockets.get(current++-players.size());
      }
      return null;
    }
  }
}