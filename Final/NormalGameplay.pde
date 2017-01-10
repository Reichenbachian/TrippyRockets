import processing.serial.*;
class NormalGameplay extends Game {
  //INVARIANTS
  //1) If IMU_MODE is set to true, there will always be at least one rocket
  //in players, and it will be the one controlled by the imu


  /**
   * Calls createGame. CreateGame is not in constructor
   * so it can be called by reset. 
   */
  public NormalGameplay() {
    super();
    createGame();
  }

  /**
   * Constructs a "Noraml Game", with given numbers of players,
   * ai rockets, and nn rockets.
   */
  public void createGame() {
    super.players.add(new PlayerRocket(width/2, height/2, true, 
      super.rocketIterator()));
  }

  /**
   * Returns roll, pitch, and yaw data if IMU_MODE is true, empty otherwise. 
   */
  public String data() {
    if (Final.IMU_MODE) {
      return super.players.get(0).data();
    }
    return "";
  }

  /**
   * Look at super class. 
   */
  public void reset() {
    super.initializeArrays();
    createGame();
  }

  /**
   * Returns score if applicable
   */
  public String header() {
    String retStr = ""+super.players.get(0).getDeaths();
    if (super.players.size() > 1) {
      retStr += ":"+super.players.get(1).getDeaths();
    }
    return retStr;
  }
}