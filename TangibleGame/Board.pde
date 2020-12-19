public class Board {

  private float rotX, rotZ;
  private final float WIDTH = 600;
  private final float HALF_WIDTH = WIDTH/2;
  private final float THICKNESS = 20;
  private final float AXIS_THICKNESS = 5;
  private final float AXIS_LENGTH = 700;
  private final float MU = 0.1;

  public Board() {
    this.rotX = 0;
    this.rotZ = 0;
  }

  public void update() {
    gameSurface.rotateZ(rotZ);
    gameSurface.rotateX(rotX);
  }

  public void draw() {
    gameSurface.fill(160, 160, 220);
    gameSurface.stroke(0);
    gameSurface.strokeWeight(2);
    gameSurface.box(WIDTH, THICKNESS, WIDTH);

    gameSurface.noStroke();
    gameSurface.fill(255, 0, 0);
    gameSurface.box(AXIS_LENGTH, AXIS_THICKNESS, AXIS_THICKNESS);
    
    gameSurface.fill(0, 255, 0);
    gameSurface.translate(0, AXIS_LENGTH/2, 0);
    gameSurface.box(AXIS_THICKNESS, AXIS_LENGTH*2, AXIS_THICKNESS);
    gameSurface.translate(0, -AXIS_LENGTH/2, 0);

    gameSurface.fill(0, 0, 255);
    gameSurface.box(AXIS_THICKNESS, AXIS_THICKNESS, AXIS_LENGTH);
  }
}
