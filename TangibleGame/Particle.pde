import java.util.Random;

class Particle {
  
  float orbitRadius = 20;
  float altitude = 0;
  float speedZ;
  float speedRadius;
  float speed = 0.4;
  float theta = 0;
  float particleRadius = 1.8;
  Random r = new Random();
  float green;
  
  public Particle() {
    theta = TAU * r.nextFloat();
    speedZ = 0.2 + r.nextFloat();
    speedRadius = 0.1 + r.nextFloat()/2;
    green = 150 + (int)(105*r.nextFloat());
  }
  
  void run() {
    float x = orbitRadius * cos(theta);
    float z = orbitRadius * sin(theta);
    gameSurface.fill(255, green, 30);
    gameSurface.translate(x, altitude, z);
    gameSurface.sphere(particleRadius);
    gameSurface.translate(-x, -altitude, -z);
    theta+=speed;
    altitude-=speedZ;
    orbitRadius+=speedRadius;
  }
  
}
