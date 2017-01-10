/**
 * Represents an animation(series of frames)
 */
class Animation {
  PImage images[];
  int current = 0;
  int speed;
  int lastUpdate = -1;
  AudioSample soundEffect;
  //maxFiles exclusive on 0 and inclusive on maxFiles
  //Directory in format 'explosion/'
  /**
   * Constructs an animation object. Loads images from given directory.
   */
  public Animation(String directory, int maxFiles, int speed, 
    PImage original, String soundName) {
    this.speed = speed;
    //this.sound = sound;
    images = new PImage[maxFiles+1];
    images[0] = original;
    for (int i = 1; i <= maxFiles; i++) {
      images[i] = loadImage(directory + i + ".png");
    }
    if (soundName != null) {
      soundEffect = minim.loadSample(soundName);
    }
  }

  /**
   * Returns next image, or null if non left. 
   */
  public PImage update(int millis) {
    if (current >= images.length) {
      return null;
    } else if (lastUpdate == -1) {
      soundEffect.trigger();
      lastUpdate = millis;
      return images[current++];
    } else if (lastUpdate + speed >= millis) {
      lastUpdate = millis;
      return images[current++];
    }
    return images[current++];
  }

  /**
   * Resets image to original image.
   */
  public PImage reset() {
    current = 0;
    lastUpdate = -1;
    return images[0];
  }
}