class ParticleSystem {

  private ArrayList<Cylinder> cylinders;
  private float spawnDelay = 0.5;
  private Villain villain;

  ParticleSystem(PVector origin) {
    cylinders = new ArrayList<Cylinder>();
    init(origin);
  }
  
  void init(PVector origin) {
    cylinders.clear();
    cylinders.add(new Cylinder(origin.x, origin.y));
    villain = new Villain(new PVector(origin.x, -Cylinder.CYLINDER_HEIGHT, origin.y));
  }

  void addParticle() {
    PVector center;
    int numAttempts = 100;
    for (int i=0; i<numAttempts; i++) {
      // Pick a cylinder and its center.
      int index = int(random(cylinders.size()));
      center = cylinders.get(index).center().copy();
      // Try to add an adjacent cylinder.
      float angle = random(TWO_PI);
      center.x += sin(angle) * 2*Cylinder.CYLINDER_BASE_SIZE;
      center.y += cos(angle) * 2*Cylinder.CYLINDER_BASE_SIZE;
      if (checkPosition(center)) {
        cylinders.add(new Cylinder(center.x, center.y));
        lastScore = -5;
        score += lastScore;
        break;
      }
    }
  }

  void display() {
    for (Cylinder c : cylinders) {
      c.run();
    }
    villain.run();
  }

  boolean checkPosition(PVector center) {
    for (Cylinder c : cylinders) {
      if (checkOverlap(c.center(), center)) return false;
    }
    return validPosition(center);
  }

  boolean checkOverlap(PVector c1, PVector c2) {
    return c2.copy().sub(c1).mag() < 2 * Cylinder.CYLINDER_BASE_SIZE;
  }

  void run() {
    if (frameCount % (int)(FRAME_RATE * spawnDelay) == 0)
      addParticle();
    display();
  }
}
