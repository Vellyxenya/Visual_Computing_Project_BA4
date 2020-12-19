import gab.opencv.*; //<>//

import java.util.List;
import java.util.Queue;
import java.util.LinkedList;
import java.util.ListIterator;

private final float MOUSE_SPEED_FACTOR = 1000;
private final float g = 9.81f/10;
private final int FRAME_RATE = 30; //TODO try to increase this nb
private final float MIN_DEPTH = 650;
private final float MAX_DEPTH = 950;

private float depth = (MAX_DEPTH + MIN_DEPTH)/2;
private float mouseSpeed = 0.008;
private int defaultFillColor;
private boolean simulate = true;

private Board board = new Board();
private ParticleSystem system;
private Ball ball;
private PShape shapeVillain;

private final float WIDTH = 1000;
private final float HEIGHT = 800;
private final float GAME_SURFACE_WIDTH = WIDTH;
private final float GAME_SURFACE_HEIGHT = 600;

private float lastScore = 0;
private float score = 0;
private float BAR_CHART_DRAW_DELAY = 1;
private HScrollbar hs;

private final float BASE_BAR_WIDTH = 6;
private final float MIN_BAR_WIDTH = 0.2;
private final int MAX_SCORE_SIZE = (int) (580 / MIN_BAR_WIDTH);
private List<Float> scores = new LinkedList<Float>();
private int scoreSize = 0;

PGraphics gameSurface;
PGraphics visualizationPanel;
PGraphics topView;
PGraphics scoreBoard;
PGraphics barChart;

ImageProcessing imgproc;

void settings() {
  size((int) WIDTH, (int) HEIGHT, P3D);
}

void setup() {
  frameRate(FRAME_RATE);
  noStroke();
  ball = new Ball();
  loadVillainAssets();
  hs = new HScrollbar(400, (int)GAME_SURFACE_HEIGHT, 10, 170, 580, 20);

  gameSurface = createGraphics((int)GAME_SURFACE_WIDTH, (int)GAME_SURFACE_HEIGHT, P3D);
  visualizationPanel = createGraphics((int)WIDTH, height - (int)GAME_SURFACE_HEIGHT, P2D);
  topView = createGraphics(200, height - (int)GAME_SURFACE_HEIGHT, P2D);
  scoreBoard = createGraphics(200, height - (int)GAME_SURFACE_HEIGHT, P2D);
  barChart = createGraphics(600, height - (int)GAME_SURFACE_HEIGHT, P2D);

  bd = new BlobDetection();
  hf = new HoughTransform();
  qg = new QuadGraph();
  
  imgproc = new ImageProcessing();
  String []args = {"Image processing window"};
  PApplet.runSketch(args, imgproc);
  
  opencv = new OpenCV(this, 100, 100); 
  td3d = new TwoDThreeD(VIDEO_WIDTH, VIDEO_HEIGHT, 0);
}

void loadVillainAssets() {
  shapeVillain = loadShape("assets/robotnik.obj");
  shapeVillain.setStroke(false);
  shapeVillain.setTexture(loadImage("assets/robotnik.png"));
  shapeVillain.scale(50);
  shapeVillain.rotate(PI, 0, 0, 1);
  shapeVillain.rotate(PI/2, 0, 1, 0);
}

void draw() {
  drawGame();
  image(gameSurface, 0, 0);

  drawVisualizationPanel();
  image(visualizationPanel, 0, GAME_SURFACE_HEIGHT);

  drawTopView();
  image(topView, 0, GAME_SURFACE_HEIGHT);

  drawScoreBoard();
  image(scoreBoard, 200, GAME_SURFACE_HEIGHT);

  drawBarChart();
  image(barChart, 400, GAME_SURFACE_HEIGHT);

  float rx = (getRotation().x > 0) ? (float) (getRotation().x - Math.PI) : (float) (getRotation().x + Math.PI);

  if(rx * 180/PI > 70) {
    rx -= PI;
  } else if(rx * 180/PI < -70) {
    rx += PI; 
  }

  if (simulate) {
    board.rotX = clamp(-rx, -PI/3, PI/3);
    board.rotZ = clamp(getRotation().z, -PI/3, PI/3);
  }

}

void drawBarChart() {
  float barWidth = MIN_BAR_WIDTH + BASE_BAR_WIDTH * hs.getPos() * 2;
  barChart.beginDraw();
  barChart.background(180, 180, 180);
  barChart.fill(255, 255, 255);
  barChart.rect(10, 10, 580, 180);
  barChart.fill(80, 0, 80);
  int i = 0;
  if (barWidth * scoreSize < 580) {
    for (float f : scores) {
      barChart.rect(10+(i++)*barWidth, 90, barWidth, clamp(-f, -80, 80));
      if ((i+1)*barWidth >= 580)
        break;
    }
  } else {
    ListIterator<Float> it = scores.listIterator(scores.size());
    while (it.hasPrevious()) {
      barChart.rect(580-(i++)*barWidth, 90, barWidth, clamp(-it.previous(), -80, 80));
      if (i*barWidth >= 580)
        break;
    }
  }
  if (frameCount % (int)(FRAME_RATE * BAR_CHART_DRAW_DELAY ) == 0 && simulate && system != null) { 
    if (scoreSize == MAX_SCORE_SIZE) {
      scores.remove(0);
      scoreSize--;
    }
    scores.add(score);
    scoreSize++;
  }
  hs.update();
  hs.display();
  barChart.endDraw();
}

void drawScoreBoard() {
  scoreBoard.beginDraw();
  scoreBoard.background(180, 180, 180);
  scoreBoard.fill(200, 200, 200);
  scoreBoard.rect(10, 10, 180, 180);
  scoreBoard.fill(0);
  scoreBoard.textSize(14);
  scoreBoard.text("Total Score :\n", 20, 30);
  scoreBoard.text(score, 20, 50);
  scoreBoard.text("Velocity :\n", 20, 90);
  scoreBoard.text(ball.velocity.mag(), 20, 110);
  scoreBoard.text("Last Score :\n", 20, 150);
  scoreBoard.text(lastScore, 20, 170);
  scoreBoard.endDraw();
}

void drawTopView() {
  topView.beginDraw();
  topView.background(180, 180, 180);
  int padding = 10;
  int viewWidth = 180;
  int viewWidth_2 = viewWidth/2;
  topView.fill(100, 150, 200);
  topView.rect(10, 10, 180, 180);
  topView.fill(0, 0, 255);
  PVector ballCoos = ball.get2DLocation();
  float x = padding + viewWidth_2 + ballCoos.x * viewWidth_2 / board.HALF_WIDTH;
  float y = padding + viewWidth_2 + ballCoos.y * viewWidth_2 / board.HALF_WIDTH;
  float r = ball.RADIUS *viewWidth / board.HALF_WIDTH;
  topView.circle(x, y, r);
  if (system != null) {
    for (Cylinder c : system.cylinders) {
      if (c == system.cylinders.get(0))
        topView.fill(255, 0, 0);
      else
        topView.fill(255, 255, 0);
      PVector cylCoos = c.center();
      x = padding + viewWidth_2 + cylCoos.x * viewWidth_2 / board.HALF_WIDTH;
      y = padding + viewWidth_2 + cylCoos.y * viewWidth_2 / board.HALF_WIDTH;
      r = Cylinder.CYLINDER_BASE_SIZE * viewWidth / board.HALF_WIDTH;
      topView.circle(x, y, r);
    }
  }
  topView.endDraw();
}

void drawVisualizationPanel() {
  visualizationPanel.beginDraw();
  visualizationPanel.background(200, 200, 200);
  visualizationPanel.endDraw();
}

void drawGame() {  
  gameSurface.beginDraw();
  if (simulate) {
    gameSurface.pushMatrix();
    gameSurface.fill(defaultFillColor);
    gameSurface.camera(width/2, -GAME_SURFACE_HEIGHT/4, depth, width/2, GAME_SURFACE_HEIGHT/2, 0, 0, 1, 0);
    gameSurface.directionalLight(50, -200, 125, 0, 1, 0);
    gameSurface.ambientLight(142, 142, 142);
    gameSurface.background(200);
    gameSurface.translate(width/2, GAME_SURFACE_HEIGHT/2, 0);
    gameSurface.fill(255);
    gameSurface.stroke(50, 0, 0);
    gameSurface.strokeWeight(1);
    gameSurface.translate(0, -depth*3/4, 0);
    gameSurface.sphere(1000);
    gameSurface.translate(0, depth*3/4, 0);
    board.update();
    board.draw();
    ball.update();
    ball.checkEdges();
    ball.display();    
    if (system != null)
      system.run();
    gameSurface.popMatrix();
  } else {
    //#########################
    //# Adding-cylinders mode #
    //#########################
    gameSurface.pushMatrix();
    gameSurface.fill(defaultFillColor);
    gameSurface.camera(width/2, -GAME_SURFACE_HEIGHT/2, 0.1, width/2, width/2, 0, 0, 1, 0);
    gameSurface.directionalLight(50, -200, 125, 0, 1, 0);
    gameSurface.ambientLight(102, 102, 102);
    gameSurface.background(240);
    gameSurface.translate(width/2, GAME_SURFACE_HEIGHT/2, 0);
    board.draw();
    ball.display();
    if (system != null)
      system.display();
    gameSurface.popMatrix();
  }
  gameSurface.endDraw();
}

boolean validPosition(PVector position) {
  if (position.x > board.WIDTH/2 - Cylinder.CYLINDER_BASE_SIZE ||
    position.x < -board.WIDTH/2 + Cylinder.CYLINDER_BASE_SIZE ||
    position.y > board.WIDTH/2 - Cylinder.CYLINDER_BASE_SIZE ||
    position.y < -board.WIDTH/2 + Cylinder.CYLINDER_BASE_SIZE
    ) {
    return false;
  }
  if (position.copy().sub(ball.get2DLocation()).mag() < Cylinder.CYLINDER_BASE_SIZE + ball.RADIUS)
    return false;
  return true;
}

void mouseClicked() {
  float x = (mouseX-GAME_SURFACE_WIDTH/2)/265.*board.WIDTH/2;
  float y = (mouseY-GAME_SURFACE_HEIGHT/2)/265.*board.WIDTH/2;
  PVector position = new PVector(x, y);
  if (!simulate) {
    if (!validPosition(position)) {
      return;
    }
    if (system == null)
      system = new ParticleSystem(position);
    else
      system.init(position);
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  mouseSpeed = clamp(mouseSpeed - e/MOUSE_SPEED_FACTOR, 1/MOUSE_SPEED_FACTOR, 10/MOUSE_SPEED_FACTOR);
}

/*void mouseDragged() {
  if (simulate && mouseY < GAME_SURFACE_HEIGHT) {
    board.rotX = clamp(board.rotX + (pmouseY-mouseY) * mouseSpeed, -PI/3, PI/3);
    board.rotZ = clamp(board.rotZ + (mouseX-pmouseX) * mouseSpeed, -PI / 3, PI/3 );
  }
}*/

private float clamp(float value, float min, float max) {
  if (value >= max)
    value = max;
  if (value <= min)
    value = min;
  return value;
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      simulate = false;
    }
    if (keyCode == UP) {
      depth = clamp(depth - 50, MIN_DEPTH, MAX_DEPTH);
    } else if (keyCode == DOWN) {
      depth = clamp(depth + 50, MIN_DEPTH, MAX_DEPTH);
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      simulate = true;
    }
  }
}
