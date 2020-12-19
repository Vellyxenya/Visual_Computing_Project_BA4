class Ball { 
  private final float RADIUS = 20;
  private final float EPSILON = 0.001f;
  private PVector location = new PVector(0, 0, 0);
  private PVector velocity = new PVector(0, 0, 0);
  private PVector gravityForce = new PVector(0, 0, 0);
  private PVector frictionForce = new PVector(0, 0, 0);
  private PVector previousVelocity = new PVector(0, 0, 0);
  private PVector normalToBoard = new PVector(0, 1, 0);
  private PVector axis = new PVector(0, 0, 0);

  private PImage img;
  private PShape globe;
  //private float ds = 0;
  private boolean victorious = false;
  private boolean animating = false;
  private int VICTORY_TIME = 40;
  private int animationTime;
  private int victoryTime;
  private final int ANIMATION_TIME = 80;
  ArrayList<Particle> particles = new ArrayList<Particle>(150);

  Ball() {
    img = loadImage("assets/earth.jpg");
    globe = createShape(SPHERE, RADIUS);
    globe.setStroke(false);
    globe.setTexture(img);
  }

  void update() {
    float normalForce = 1;
    float frictionMagnitude = normalForce * board.MU;

    frictionForce = velocity.copy(); 
    frictionForce.mult(-1);
    frictionForce.normalize();
    frictionForce.mult(frictionMagnitude);
    velocity.add(frictionForce);
    gravityForce.x = sin(board.rotZ) * g;
    gravityForce.z = sin(-board.rotX) * g;
    velocity.add(gravityForce);

    PVector temp = location.copy();
    location.add(velocity);
    //ds = location.copy().sub(temp).mag();
    axis = velocity.cross(normalToBoard).normalize();

    previousVelocity = velocity;
    checkCylinderCollision();
  }

  void display() {
    gameSurface.pushMatrix();

    gameSurface.fill(255, 230, 230);
    gameSurface.noStroke();
    gameSurface.translate(clamp(location.x), -(RADIUS + board.THICKNESS/2), clamp(location.z));

    for (Particle p : particles) {
      p.run();
    }

    roll();
    gameSurface.shape(globe);
    gameSurface.popMatrix();

    if (victorious) {
      createParticles();
      victoryTime--;
      if (victoryTime < 0) {
        victorious = false;
      }
    }
    
    if (animating) {
      animationTime--;
      if(animationTime <= 0) {
        animating = false;
        particles.clear();
      }
    }
  }

  void createParticles() {
    for (int i = 0; i < 3; i++) {
      particles.add(new Particle());
    }
  }

  void roll() {
    gameSurface.rotate((velocity.mag() * 20 / RADIUS) %360, axis.x, axis.y, axis.z);
  }

  private float clamp(float value) {
    if (value >= board.WIDTH/2 - RADIUS)
      value = board.WIDTH/2 - RADIUS - EPSILON;
    if (value <= -board.WIDTH/2 + RADIUS)
      value = -board.WIDTH/2 + RADIUS + EPSILON;
    return value;
  }

  void checkCylinderCollision() {
    if (system == null)
      return;
    ArrayList<Cylinder> deadCylinders = new ArrayList<Cylinder>();
    for (Cylinder cylinder : system.cylinders) {
      if (distance(location, cylinder.position) < RADIUS + Cylinder.CYLINDER_BASE_SIZE) {
        PVector n = location.copy().sub(cylinder.position);
        n.y = 0;
        n = n.normalize();
        location = location.sub(previousVelocity);
        velocity = velocity.sub(n.mult(2*velocity.dot(n)));
        velocity = velocity.mult(Cylinder.DAMP_COEFF);
        deadCylinders.add(cylinder);
        lastScore = velocity.mag();
        score += lastScore;
        if (cylinder == system.cylinders.get(0)) {
          victorious = true;
          animating = true;
          animationTime = ANIMATION_TIME;
          victoryTime = VICTORY_TIME;
          system = null;
          return;
        }
      }
    }
    system.cylinders.removeAll(deadCylinders);
  }

  private PVector get2DLocation() {
    return new PVector(location.x, location.z);
  }

  private float distance(PVector p1, PVector p2) {
    float dx = (p2.x - p1.x);
    float dz = (p2.z - p1.z);
    return (float) Math.sqrt(dx*dx + dz*dz);
  }

  void checkEdges() {
    if (location.x > board.WIDTH/2 - RADIUS) {
      location.x = board.WIDTH/2 - RADIUS;
      velocity.x *= -1;
    } else if (location.x < -(board.WIDTH/2 - RADIUS)) {
      location.x = -(board.WIDTH/2 - RADIUS);
      velocity.x *= -1;
    }
    if (location.z > board.WIDTH/2 - RADIUS) {
      location.z = board.WIDTH/2 - RADIUS;
      velocity.z *= -1;
    } else if (location.z < -(board.WIDTH/2 - RADIUS)) {
      location.z = -(board.WIDTH/2 - RADIUS);
      velocity.z *= -1;
    }
  }
}
