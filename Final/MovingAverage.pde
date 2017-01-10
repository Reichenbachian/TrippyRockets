/**
 * Public class that represents a moving average for
 * noisy daya.
 */
public class MovingAverage {
  private float input[];
  private int size;
  private float total;
  //Index represents index next to be replaced
  private int index;
  private float offset;
  private boolean full;

  /**
   * Constructs a moving average object.
   */
  public MovingAverage(int bufferSize) {
    input = new float[bufferSize];
    //Initially all data is zero and average is inaccurate
    //Data is fast enough, however, that this time is minimal
    size = bufferSize;
    total = 0;
    full = false;
  }

  /**
   * Done on circle to save remove(0)'s O(n) time.
   * I know it's a miniscule time difference, but
   * I believe the slightly more obscure code is 
   * worth the time improvement
   */
  public void add(float serialData) {
    if (index+1 == input.length) {
      full = true;
    }
    total-=input[index];
    total+=serialData;
    input[index] = serialData;
    index = (index+1)%size;
  }

  /**
   * Sets an offset that remains constant until next time zero is called.
   */
  public void zero() {
    offset = (total / size);
  }

  /**
   * Returns current moving average.
   */
  public float getAverage() {
    return (total / size) - offset;
  }

  /**
   * Returns if the average has been filled with values yet.
   */
  public boolean isFull() {
    return full;
  }
}