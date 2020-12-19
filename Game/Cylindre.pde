class Cylinder {

  private static final float CYLINDER_BASE_SIZE = 30;
  private static final float CYLINDER_HEIGHT = 50;
  private static final int CYLINDER_RESOLUTION = 40;
  private static final float DAMP_COEFF = 0.7f;
  private PShape openCylinder = new PShape();
  private PShape cylinderTop = new PShape();
  private PVector position;

  public Cylinder(float xPosition, float zPosition) {
    float angle;
    position = new PVector(xPosition, -board.THICKNESS/2, zPosition);
    float[] x = new float[CYLINDER_RESOLUTION + 1];
    float[] y = new float[CYLINDER_RESOLUTION + 1];
    //get the x and y position on a circle for all the sides
    for (int i = 0; i < x.length; i++) {
      angle = (TWO_PI / CYLINDER_RESOLUTION) * i;
      x[i] = sin(angle) * CYLINDER_BASE_SIZE;
      y[i] = cos(angle) * CYLINDER_BASE_SIZE;
    }
    
    openCylinder = createShape();
    openCylinder.beginShape(QUAD_STRIP);
    openCylinder.fill(255, 255, 0);
    openCylinder.stroke(50, 50, 150);
    openCylinder.strokeWeight(0.5);
    //draw the border of the cylinder
    for (int i = 0; i < x.length; i++) {
      openCylinder.vertex(x[i], 0, y[i]);
      openCylinder.vertex(x[i], -CYLINDER_HEIGHT, y[i]);
    }
    openCylinder.endShape();

    cylinderTop = createShape();
    cylinderTop.beginShape(TRIANGLE_FAN);
    cylinderTop.fill(255, 255, 0);
    cylinderTop.stroke(50, 50, 150);
    cylinderTop.strokeWeight(0.5);
    cylinderTop.vertex(0, -CYLINDER_HEIGHT, 0);
    for (int i = 0; i < x.length; i++) {
      cylinderTop.vertex(x[i], -CYLINDER_HEIGHT, y[i]);
    }
    cylinderTop.endShape();
  }

  public PVector center() {
    return new PVector(position.x, position.z);
  }

  void run() {
    display();
  }

  void display() {
    gameSurface.fill(255, 200, 200);
    gameSurface.translate(position.x, position.y, position.z);
    gameSurface.shape(openCylinder);
    gameSurface.shape(cylinderTop);
    gameSurface.translate(-position.x, -position.y, -position.z);
  }
}
