import processing.serial.*;
class Survival extends Game {
  private static final int NUM_LIVES = 3;
  private static final int TIME_FOR_TEXT = 3000;
  private int score = 1;
  private int timerForText;
  int timerInSeconds;
  int previousTime;

  //INVARIANTS
  //1) If IMU_MODE is set to true, there will always be at least one rocket
  //in players, and it will be the one controlled by the imu

  /**
   * Calls createGame. CreateGame is not in constructor so it can be called by reset. 
   */
  public Survival() {
    createGame(1);
    this.timerForText = Integer.MIN_VALUE;
  }

  /**
   * Constructs a "Noraml Game", with given numbers of players.
   */
  public void createGame(int humanPlayers) {
    previousTime = millis();
    timerInSeconds = 0;
    for (int i = 0; i < humanPlayers; i++) {
      super.players.add(new PlayerRocket(-1, -1, Final.IMU_MODE, super.rocketIterator()));
    }
    for (int i = 0; i < score; i++) {
      super.aiRockets.add(new AIRocket(-1, -1, super.rocketIterator()));
    }
  }

  /**
   * Returns roll, pitch, and yaw data if IMU_MODE is true, empty otherwise. 
   */
  public String data() {
    return "Level: " + score;
  }

  public void handleMousePress(int daMouseX, int daMouseY) {
    for (PlayerRocket player : super.players) {
      player.zero();
    }
    for (Rocket enemy : super.aiRockets) {
      enemy.zero();
    }
  }

  /**
   * Draws the Survival game board.
   */
  public void draw() {
    timer();
    if (timerForText + TIME_FOR_TEXT >= millis()) {
      fill(255);
      textFont(labelFont, 40);
      text("YOU LOSE!", width/2, height/2);
    }
    if (super.players.size() > 0 && super.players.get(0).getDeaths() >= NUM_LIVES) {
      reset();
      timerForText = millis();
    }
    if (super.aiRockets.size() == 0) {
      score++;
      createGame(0);
    }
    for (PlayerRocket player : super.players) {
      if (!player.update()) {
        System.out.println("YOU LOST!");
        mousePressed();
      } else {
        player.draw();
      }
    }
    super.draw();
  }

  /**
   * Look at super class. 
   */
  public void reset() {
    super.initializeArrays();
    score = 0;
    createGame(1);
  }

  /**
   * Returns a timer string
   */
  public String header() {
    return ""+timerInSeconds;
  }

  /**
   * Done this way instead of millis%1000 for a more reliable result, especially
   * at beginning
   */
  public int timer() {
    if (previousTime+1000 <= millis()) {
      previousTime = millis();
      timerInSeconds++;
    }
    return timerInSeconds;
  }
}