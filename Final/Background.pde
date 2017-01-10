//Creds: https://www.processing.org/discourse/beta/num_1209965886.html //<>//
//For stars example and code.

//Creds: https://forum.processing.org/two/discussion/1747/reading-filesnames-from-a-folder
//For reading file names from a folder

//Creds: https://forum.processing.org/one/topic/new-to-processing-and-need-help-with-ripple-effect-urgent.html
//For wave/circles example and code.

//Creds: Songs from http://www.bensound.com/royalty-free-music/corporate-pop
//For background audio


//Visualizers
private static final int NUM_BANDS = 80;
private static final int NUM_TOP_BANDS = 24;
//Y scale of visualizer
private static final int VISUALIZER_SCALE = 10;
//Moving average buffer of visualizer
private static final int VISUALIZER_BUFFER = 15;
//Beziers
private static final int TRAILING_DISTANCE = 20;
private static final int FADE_VALUE = 10;
private static final int FADE_CUTOFF = 3;
private static final int BEZIER_INITIIAL_ALPHA = 20;
private static final int SQUIGGLE_PERIOD = 100;
private static final float BEZIER_VARIANT = 20;
private static final float BEZIER_MOVING_SPEED = 4;
//Circles
private static final float CIRCLE_ALPHA = 50;
private static final int WAVE_NUMBER = 50;
//Stars
private static final int NUM_STARS=400;
private static final int SPREAD=64;
private static final float SPEED=.5;
private static final float LOGARITHMIC_CORRECTION = 1.02;

private float bandWidth;
Audio audio;
/**
 * Represents an interface for a background element(sound, color, etc)
 */
interface BackgroundElement {
  /**
   * Draws and updates the background element.
   * Also does collision detection if applicable.
   */
  public void update(int xCoord, int yCoord);
}

/**
 * Class that encompasses the background.
 */
public class Background {
  BackgroundElement bbV;
  BackgroundElement tbV;
  BackgroundElement squig;
  BackgroundElement circ;
  BackgroundElement stars;
  /**
   * Constructs a new background and starts a song.
   */
  public Background(int xPos, int yPos) {
    bbV = new BottomBarVisualizer();
    tbV = new TopBarVisualizer();
    audio = new Audio();
    squig = new Squiggle(xPos, yPos);
    circ = new ExpandingCircles();
    stars = new Stars();
  }

  /**
   * Updates all the background elements.
   */
  public void update(int xPos1, int yPos1, int xPos2, int yPos2) {
    bandWidth = NUM_BANDS/NUM_TOP_BANDS;
    noFill();
    if (game.players.size() >= 1) {
      squig.update(xPos1, yPos1);
    }
    if (game.players.size() >= 2) {
      circ.update(xPos2, yPos2);
    }
    //They don't need to know actual position
    stars.update(-1, -1);
    audio.update(-1, -1);
    bbV.update(-1, -1);
    tbV.update(-1, -1);
  }

  /**
   * Stops the audio
   */
  public void stopAudio() {
    audio.stopAudio();
  }
}

//==============================================================================
// Visualizers
//==============================================================================

/**
 * The bottom bar visualizer
 * Much of this code was taken from example FFT sound project!
 */
private class BottomBarVisualizer implements BackgroundElement {

  /**
   * Reference interface
   */
  public void update(int xCoord, int yCoord) {
    fill(140, 0, 30);
    strokeWeight(2);
    stroke(10, 100, 30);
    for (int i = 0; i < NUM_BANDS; i++) {
      float barHeight = -audio.correctedFrequencyAt(i)*VISUALIZER_SCALE;
      float barXCoord = i*audio.getWidth();
      // smooth the FFT data by smoothing factor
      game.checkCollisionBottomVisualizer(barXCoord, audio.getWidth(), barHeight);
      // draw the rects with a scale factor
      rect(barXCoord, height, audio.getWidth(), barHeight);
    }
  }
}

/**
 * Represents the top bar visualizer
 */
private class TopBarVisualizer implements BackgroundElement {
  /**
   * Reference interface
   */
  public void update(int xCoord, int yCoord) {
    stroke(180);
    strokeWeight(3);
    noFill();
    float previousHeight = 0;
    float previousXCoord = width;
    for (int i = 0; i < NUM_BANDS; i+=bandWidth) {
      float barHeight = audio.correctedFrequencyAt(i)*VISUALIZER_SCALE+Final.TOP_BAR_SIZE;
      float barXCoord = width-i*audio.getWidth();
      game.checkCollisionTopVisualizer(previousXCoord, previousHeight, barXCoord, barHeight);
      // draw the rects with a scale factor
      ellipse(barXCoord, barHeight, 10, 10);
      line(previousXCoord, previousHeight, barXCoord, barHeight);
      previousXCoord = barXCoord;
      previousHeight = barHeight;
    }
    line(0, Final.TOP_BAR_SIZE, previousXCoord, previousHeight);
  }
}


//==============================================================================
// STARS
//==============================================================================
/**
 * Based on code from
 * https://www.processing.org/discourse/beta/num_1209965886.html
 */
private class Stars implements BackgroundElement {
  Star[] s = new Star[NUM_STARS];
  int CX, CY;
  private class Star { 
    float x=0, y=0, z=0, dx=0, dy=0;

    /**
     * Sets star at random position
     */
    void SetPosition() {
      z=(float) random(200, 255);
      x=(float) random(-1000, 1000);
      y=(float) random(-1000, 1000);
    }

    /**
     * Draws the star taking into account it's speed.
     */
    void DrawStar() {
      if (z<SPEED) {
        this.SetPosition();
      }
      z-=SPEED;
      dx=(x*SPREAD)/(z)+CX;
      dy=(y*SPREAD)/(4+z)+CY;
      if (dx<0 | dx>width) {
        this.SetPosition();
      }
      if (dy<0 | dy>height) {
        this.SetPosition();
      }
      fill(color(255 - (int) z, 255 - (int) z, 255 - (int) z));
      ellipse( (int) dx, (int) dy, 3, 3);
    }
  }

  /**
   * Constructs stars object
   */
  public Stars() {
    CX=width/2 ; 
    CY=height/2;
    for (int i=0; i<NUM_STARS; i++) {
      s[i] = new Star();
      s[i].SetPosition();
    }
  }

  /**
   * Reference interface
   */
  public void update(int xCoord, int yCoord) {
    noStroke();
    for (int i=0; i<NUM_STARS; i++) {
      s[i].DrawStar();
    }
  }
}

//==============================================================================
// BACKGROUND AUDIO
//==============================================================================

/**
 * The background audio.
 */
private class Audio implements BackgroundElement {
  private Minim minim;
  private int nextSong;
  private AudioPlayer song;
  FFT fft;
  MovingAverage[] movingFrequency;
  float[] currentFrameFrequency;

  /**
   * Creates and starts a song.
   */
  public Audio() {
    minim = new Minim(Final.this);
    startSong();
    setCountdown();
    //FFT is initialized in startSong() function.
    movingFrequency = new MovingAverage[NUM_BANDS];
    currentFrameFrequency = new float[NUM_BANDS];
    for (int i = 0; i < movingFrequency.length; i++) {
      movingFrequency[i] = new MovingAverage(VISUALIZER_BUFFER);
    }
  }

  /**
   * Starts the song with a random file from song folder
   */
  public void startSong() {
    //Lists the songs to find the next one
    //Creds: https://forum.processing.org/two/discussion/1747/reading-filesnames-from-a-folder
    //for reading file names from folder
    File folder = new File(dataPath("songs/"));
    String[] filenames = folder.list();
    assert(filenames.length >= 2);
    List<String> filtered = new ArrayList<String>();
    for (int i = 0; i < filenames.length; i++) {
      if (filenames[i].contains(".mp3") || filenames[i].contains(".wav")) {
        filtered.add(filenames[i]);
      }
    }
    //Tries to start playing it.
    try {
      String songTitle = filtered.get((int)random(filtered.size()));
      song = minim.loadFile(dataPath("songs/"+ songTitle));
      song.play();
    } 
    catch (RuntimeException e) {
      System.out.println("AUDIO FAILURE");
    }
    fft = new FFT(song.bufferSize(), song.sampleRate());
    setCountdown();
  }

  /**
   * Sets the countdown for the song
   */
  public void setCountdown() {
    //Give 500 millisecond gap in between songs
    nextSong+=millis()+song.length()+500;
  }

  /**
   * Stops the song and audio sampler.
   */
  public void stopAudio() {
    song.close();
    minim.stop();
  }

  /**
   * Different than normal update!!!
   * Starts new song if current one is done
   */
  public void update(int xCoord, int yCoord) {
    if (millis() > nextSong) {
      startSong();
      setCountdown();
    }
    fft.forward(song.mix);
    float movingFrequencyPerBar = fft.specSize()/(NUM_BANDS);
    float sum = 0;
    for (int i = 0; i < fft.specSize(); i++) {
      sum += fft.getBand(i);
      //Done in this strange manner to loop through only once.
      int index = (int)(i/movingFrequencyPerBar);
      if (i%movingFrequencyPerBar == 0 && index < movingFrequency.length) {
        movingFrequency[index].add(sum/movingFrequencyPerBar);
        sum=0;
      }
    }
    for (int i = 0; i < movingFrequency.length; i++) {
      currentFrameFrequency[i] = movingFrequency[i].getAverage();
    }
  }

  /**
   * Returns width of bar.
   */
  public float getWidth() {
    return (float)width/(NUM_BANDS+1);
  }

  /**
   * Returns corrected frequency, given humans logarithmic hearing
   * Creds: Dr. Miles for bringing this correction to my attention
   */
  public float correctedFrequencyAt(int i) {
    if (i >= movingFrequency.length || i < 0) {
      throw new RuntimeException("Requested frequency out of range");
    }
    return (float)(currentFrameFrequency[i]*Math.pow(LOGARITHMIC_CORRECTION, i));
  }
}

//==============================================================================
// CHARACTER IDENTIFIERS
//==============================================================================

private class Squiggle implements BackgroundElement {
  private LinkedBezier root;
  private LinkedBezier beziers[] = new LinkedBezier[50];
  private int bufferIndex = 0;
  //Current color of squiggle
  private float[] currentColor = new float[3];
  //Color that it is heading towards.
  private float[] goalColor = new float[3];
  private int previousTime;
  private int currentX;
  private int currentY;

  /**
   * Creates a squiggle object.
   */
  public Squiggle(int rootXCoord, int rootYCoord) {
    noFill();
    root = new LinkedBezier(rootXCoord, rootYCoord, null);
    currentX = rootXCoord;
    currentY = rootYCoord;
    currentColor[0] = random(255);
    currentColor[1] = random(255);
    currentColor[2] = random(255);
    goalColor[0] = random(255);
    goalColor[1] = random(255);
    goalColor[2] = random(255);
    previousTime = millis();
    for (int i = 0; i < beziers.length; i++) {
      //Create all root linked beziers at first
      beziers[i] = root.copy();
    }
  }

  /**
   * Updates the squiggle object
   */
  public void update() {
    //Move our color towards goal
    for (int i = 0; i < 3; i++) {
      if (currentColor[i] == goalColor[i]) {
        if (i == 3) {
          goalColor[i] = random(10);
        } else {
          goalColor[i] = random(220)+10;
        }
      } else if (currentColor[i] < goalColor[i]) {
        currentColor[i]+=.5;
      } else {
        currentColor[i]-=.5;
      }
    }
    //Add new root at front of linkedBezier
    if (previousTime+SQUIGGLE_PERIOD <= millis()) {
      root.addNewRoot(currentX, currentY);
      root = root.parent;
      previousTime = millis();
    }
    //Rotate current index
    bufferIndex++;
    bufferIndex%=beziers.length;
    beziers[bufferIndex] = root.copy();
    //Draws linked beziers
    for (int i = 0; i < beziers.length; i++) {
      beziers[i].draw(currentColor[0], currentColor[1], currentColor[2], 
        BEZIER_INITIIAL_ALPHA);
    }
    root.update();
  }

  /**
   * Reference interface
   */
  public void update(int x, int y) {
    this.currentX = x;
    this.currentY = y;
    this.update();
  }

  /**
   * Represents a bezier which has a reference to another bezier
   * thus a linked bezier
   */
  private class LinkedBezier {
    BezierPoint anchor2;
    BezierPoint control2;
    LinkedBezier next;
    LinkedBezier parent;

    /**
     * Create root bezier
     */
    public LinkedBezier(int xPos, int yPos) {
      anchor2 = new BezierPoint(xPos, yPos);
      control2 = new BezierPoint(xPos, yPos);
    }

    /**
     * Create linked bezier piece.
     */
    public LinkedBezier(int xPos, int yPos, LinkedBezier linked) {
      parent = linked;
      anchor2 = new BezierPoint(xPos, yPos);
      control2 = new BezierPoint(xPos+random(BEZIER_VARIANT), 
        yPos+random(BEZIER_VARIANT));
    }

    /**
     * Updates whole link of beziers
     */
    public void update() {
      if (next != null) {
        next.update();
      }
      anchor2.update();
      control2.update();
    }

    /**
     * draws the beziers 
     */
    public void draw(float r, float g, float b, float alpha) {
      stroke(r, g, b, alpha);
      float parentAnchorX;
      float parentAnchorY;
      float parentControlX;
      float parentControlY;
      //If parent is null parent anchor is rocket position
      if (parent == null) {
        parentAnchorX = game.players.get(0).getX();
        parentAnchorY = game.players.get(0).getY();
        parentControlX = game.players.get(0).getX() + 
          sin(game.players.get(0).getRot())*TRAILING_DISTANCE;
        parentControlY = game.players.get(0).getY() - 
          cos(game.players.get(0).getRot())*TRAILING_DISTANCE;
      } else {
        parentAnchorX = parent.anchor2.xPos;
        parentAnchorY = parent.anchor2.yPos;
        parentControlX = parent.control2.xPos;
        parentControlY = parent.control2.yPos;
      }
      //Flip control point over parent point to create smooth transition between beziers.
      float flippedParentControlX =  -parentControlX + 2*parentAnchorX;
      float flippedParentControlY =  -parentControlY + 2*parentAnchorY;
      strokeWeight(1);
      bezier(parentAnchorX,parentAnchorY,flippedParentControlX,flippedParentControlY, 
        control2.xPos, control2.yPos, anchor2.xPos, anchor2.yPos);
      if (next != null) {
        if (alpha < FADE_CUTOFF) {
          next = null;
          return;
        }
        next.draw(r, g, b, alpha-FADE_VALUE);
      }
    }

    /**
     * Adds new root to linked bezier
     */
    public void addNewRoot(int xPos, int yPos) {
      parent = new LinkedBezier(xPos, yPos);
      parent.control2.xPos = xPos;
      parent.control2.xPos = yPos;
      this.parent.next = this;
    }

    /**
     * Adds new piece to the end to the linked bezier
     */
    public void addNext(int xPos, int yPos) {
      next = new LinkedBezier(xPos, yPos);
    }

    /**
     * Returns a copy of the linked bezier. 
     */
    public LinkedBezier copy() {
      LinkedBezier retRoot = new LinkedBezier((int)anchor2.xPos, (int)anchor2.yPos);
      LinkedBezier retLB = retRoot;
      LinkedBezier current = this;
      while (current.next != null) {
        retLB.addNext((int)current.anchor2.xPos, (int)current.anchor2.yPos);
        retLB.anchor2.xPos = current.anchor2.xPos;
        retLB.anchor2.yPos = current.anchor2.yPos;
        retLB.control2.xPos = current.control2.xPos;
        retLB.control2.yPos = current.control2.yPos;
        retLB.addNewRoot((int)current.next.anchor2.xPos,(int)current.next.anchor2.yPos);
        retLB = retLB.next;
        current = current.next;
      }
      return retRoot;
    }
  }

  /**
   * Represents a bezier specific point
   */
  private class BezierPoint extends Point {
    float yGoal;
    float xGoal;

    /**
     * Contructs Bezier point
     */
    public BezierPoint(float xPos, float yPos) {
      super.xPos = xPos;
      super.yPos = yPos;
      this.xGoal = super.xPos;
      this.yGoal = random(height);
      randomY();
      randomX();
    }

    /**
     * Updates bezier point
     */
    void update() {
      //Move x and y towards goal. If closer than 1, find new goal.
      if (Math.abs(super.yPos - yGoal) < 1) {
        randomY();
      } else if (super.yPos < yGoal) {
        yPos += BEZIER_MOVING_SPEED;
      } else if (super.yPos > yGoal) {
        yPos -= BEZIER_MOVING_SPEED;
      }
      if (Math.abs(super.xPos - xGoal) < 1) {
        randomX();
      } else if (super.xPos < xGoal) {
        xPos += BEZIER_MOVING_SPEED;
      } else if (super.xPos > xGoal) {
        xPos -= BEZIER_MOVING_SPEED;
      }
    }

    /**
     * Generate Random valid x coordinate
     */
    void randomX() {
      xGoal = random(BEZIER_VARIANT*2)-BEZIER_VARIANT+super.xPos;
    }

    /**
     * Generate Random valid y coordinate
     */
    void randomY() {
      yGoal = random(BEZIER_VARIANT*2)-BEZIER_VARIANT+super.yPos;
    }
  }
}

//Wave class credit to
//https://forum.processing.org/one/topic/new-to-processing-and-need-help-with-ripple-effect-urgent.html
//Modified to have O(1) running time for combined adding and removing
private class ExpandingCircles implements BackgroundElement {
  Wave waves[] = new Wave[WAVE_NUMBER];
  int currentWave = 0;
  int xCoord;
  int yCoord;

  public ExpandingCircles() {
    ellipseMode(CENTER);
  }

  public void update(int xCoord, int yCoord) {
    this.xCoord = xCoord;
    this.yCoord = yCoord;
    //Create a new Wave
    Wave w = new Wave();
    waves[currentWave] = w;
    currentWave++;
    currentWave%=waves.length;
    //Run through all the waves
    for (int i = 0; i < waves.length; i ++) {
      //If waves is not full
      if (waves[currentWave] == null) {
        break;
      }
      //Run the Wave methods
      waves[i].update();
      waves[i].display();
    }
  }
  class Wave {
    //Location
    PVector loc;
    //In case you are not familiar with PVectors, you can
    //think of it as a point; it holds an x and a y position

    //The distance from the wave origin
    int farOut;

    //Color
    color strokeColor;

    Wave() {
      //Initialize the Location PVector
      loc = new PVector();

      //Set location to the Mouse Position
      loc.x = xCoord;
      loc.y = yCoord;

      //Set the distance out to 1
      farOut = 1;

      //Randomize the Stroke Color
      strokeColor = color(random(255), random(255), random(255), CIRCLE_ALPHA);
    }

    public void update() {
      //Increase the distance out
      farOut += 1;
    }

    public void display() {
      //Set the Stroke Color
      stroke(strokeColor);

      //Draw the ellipse
      ellipse(loc.x, loc.y, farOut, farOut);
    }
  }
}