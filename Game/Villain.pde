class Villain {

  PVector location;
  PVector location2D;

  public Villain(PVector location) {
    this.location = location;
    this.location2D = new PVector(location.x, location.z);
  }

  void run() {
    gameSurface.pushMatrix();
    gameSurface.fill(255, 230, 230);
    gameSurface.noStroke();
    gameSurface.translate(location.x, location.y, location.z);
    lookAt(ball.get2DLocation());
    gameSurface.shape(shapeVillain);
    gameSurface.popMatrix();
  }

  void lookAt(PVector v) {
    PVector vect = v.copy().sub(location2D);
    float angle = (float) Math.atan2(vect.y, vect.x);
    gameSurface.rotate(-angle, 0, 1, 0);
  }
}
