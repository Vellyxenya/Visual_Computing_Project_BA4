import processing.video.*;
import gab.opencv.*;
import java.util.List;

OpenCV opencv;
Capture cam;
PImage capturedImage;

HScrollbar thresholdBar1;
HScrollbar thresholdBar2;
HScrollbar thresholdBar3;
HScrollbar thresholdBar4;
HScrollbar thresholdBar5;
HScrollbar thresholdBar6;

PImage img;
PImage reference;

BlobDetection bd;
HoughTransform hf;
QuadGraph qg;
TwoDThreeD td3d;

private boolean useCamera = false;

float[][] kernel1 = {
  { 0, 0, 0 }, 
  { 0, 2, 0 }, 
  { 0, 0, 0 }};

float[][] kernel2 = {
  { 0, 1, 0 }, 
  { 1, 0, 1 }, 
  { 0, 1, 0 }};

float[][] sobel = {
  { -1, 0, 1 }, 
  { -2, 0, 2 }, 
  { -1, 0, 1 }};

float[][] gaussianKernel = {
  { 9, 12, 9 }, 
  { 12, 15, 12 }, 
  { 9, 12, 9 }};

void useCamera() {
  useCamera = true;
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, 640, 480, cameras[0]);
    cam.start();
  }
}

void settings() {
  size(1600, 600);
  //useCamera();
}

void setup() {
  frameRate(20);
  //img = loadImage("nao.jpg");
  img = loadImage("nao.jpg");
  //img = loadImage("BlobDetection_Test.bmp");

  reference = loadImage("board1Scharr_new.bmp");
  surface.setSize((int)img.width*2, (int)img.height);
  thresholdBar1 = new HScrollbar(0, img.height-130, img.width, 20);
  thresholdBar2 = new HScrollbar(0, img.height-108, img.width, 20);
  thresholdBar3 = new HScrollbar(0, img.height-86, img.width, 20);
  thresholdBar4 = new HScrollbar(0, img.height-64, img.width, 20);
  thresholdBar5 = new HScrollbar(0, img.height-42, img.width, 20);
  thresholdBar6 = new HScrollbar(0, img.height-20, img.width, 20);

  bd = new BlobDetection();
  hf = new HoughTransform();
  qg = new QuadGraph();
  opencv = new OpenCV(this, 100, 100);
  td3d = new TwoDThreeD(img.width, img.height, 0);

  noLoop(); // no interactive behaviour: draw() will be called only once.
}

void draw() {
  //drawGreenAndRed();
  //useThresholdBars();
  //functionsTesting();
  //extractBoardEdge();
  houghTransform();

  //drawCamera();

  //System.out.println("Are the 2 images equal? : " + imagesEqual(reference, img2));
}


void drawCamera() {
  if (useCamera) {
    if (cam.available() == true) {
      cam.read();
    }
    capturedImage = cam.get();
    image(capturedImage, 0, 0);
    img = capturedImage;
  }
}

void houghTransform() {
  image(img, 0, 0);//show original image

  PImage img2 = img.copy();//make a deep copy
  img2.loadPixels();// load pixels

  img2 = thresholdHSB(img2, 80, 140, 70, 255, 0, 255); //<---perfect blob (board)
  img2 = bd.findConnectedComponents(img2, true, color(255));
  img2 = convolute(img2, gaussianKernel);
  img2 = scharr(img2);

  List<PVector> lines = hf.hough(img2, false, 4);
  List<PVector> quads = qg.findBestQuad(lines, img2.width, img2.height, img2.width*img2.height, 100*100, true);

  displayLines(lines);
  displayQuads(quads);

  List<PVector> homogeneousQuads = new ArrayList<PVector>();
  for (PVector quad : quads) {
    homogeneousQuads.add(homogeneous3DPoint(quad));
  }
  PVector r = td3d.get3DRotations(homogeneousQuads);
  System.out.println("Rx : " + Math.toDegrees(r.x) + ", Ry : " +Math.toDegrees(r.y) + ", Rz : " + Math.toDegrees(r.z));

  img2.updatePixels();
  image(img2, img.width, 0);
}

PVector homogeneous3DPoint(PVector p) {
  return new PVector(p.x, p.y, 1);
}

void displayQuads(List<PVector> quads) {
  for (PVector vect : quads) {
    float radius = 8;
    fill(255, 0, 0);
    circle(vect.x, vect.y, radius);
  }
}

void displayLines(List<PVector> lines) {
  for (int idx = 0; idx < lines.size(); idx++) {
    PVector line=lines.get(idx);
    float r = line.x;
    float phi = line.y;

    int x0 = 0;
    int y0 = (int) (r / sin(phi));
    int x1 = (int) (r / cos(phi));
    int y1 = 0;
    int x2 = img.width;
    int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi));
    int y3 = img.width;
    int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));
    // Finally, plot the lines
    stroke(204, 102, 0);
    if (y0 > 0) {
      if (x1 > 0)
        line(x0, y0, x1, y1);
      else if (y2 > 0)
        line(x0, y0, x2, y2);
      else
        line(x0, y0, x3, y3);
    } else {
      if (x1 > 0) {
        if (y2 > 0)
          line(x1, y1, x2, y2);
        else
          line(x1, y1, x3, y3);
      } else
        line(x2, y2, x3, y3);
    }
  }
}

void extractBoardEdge() {
  image(img, 0, 0);//show original image

  PImage img2 = img.copy();//make a deep copy
  img2.loadPixels();// load pixels

  //img2 = thresholdHSB(img, 117, 133, 25, 112, 115, 255);
  //img2 = thresholdHSB(img, 46, 132, 38, 124, 115, 255);
  //img2 = convolute(img2, gaussianKernel, 99);
  //img2 = thresholdHSB(img, 46, 130, 46, 115, 115, 255); //<---very sparse
  //img2 = thresholdHSB(img, 87, 138, 70, 255, 90, 255); //<---dense
  //img2 = thresholdHSB(img2, 109, 135, 39, 255, 58, 157); //<---blob

  img2 = thresholdHSB(img2, 80, 140, 70, 255, 0, 255); //<---perfect blob (board)
  img2 = bd.findConnectedComponents(img2, true, color(255));
  img2 = convolute(img2, gaussianKernel);
  img2 = scharr(img2);

  img2.updatePixels();
  image(img2, img.width, 0);
}

void drawGreenAndRed() {
  image(img, 0, 0);

  PImage board = img.copy();
  board.loadPixels();
  PImage redObj = img.copy();
  redObj.loadPixels();

  board = thresholdHSB(board, 80, 140, 70, 255, 0, 255); //<---perfect blob (board)
  redObj = thresholdHSB(redObj, 234, 17, 27, 255, 95, 255); //<---perfect blob (red thing)

  board = bd.findConnectedComponents(board, true, color(0, 255, 0));
  redObj = bd.findConnectedComponents(redObj, true, color(255, 0, 0));

  PImage greenAndRed = add(board, redObj);

  greenAndRed.updatePixels();
  image(greenAndRed, img.width, 0);
}

void functionsTesting() {
  image(img, 0, 0);//show original image

  PImage img2 = img.copy();//make a deep copy
  img2.loadPixels();// load pixels
  //halfGreen(img2);
  //img2 = threshold(img2, (int)(255*thresholdBar.getPos()), true);
  //img2 = truncate(img2, 128);
  //img2 = hueMap(img);
  //img2 = selectHuesIn(img, (int)(255*thresholdBar1.getPos()), (int)(255*thresholdBar2.getPos()));
  //img2 = thresholdHSB(img2, 100, 200, 100, 255, 45, 100);

  /*img3 = thresholdHSB(img3, 
   (int)(255*thresholdBar1.getPos()), (int)(255*thresholdBar2.getPos()), 
   (int)(255*thresholdBar3.getPos()), (int)(255*thresholdBar4.getPos()), 
   (int)(255*thresholdBar5.getPos()), (int)(255*thresholdBar6.getPos()));*/

  //img2 = convolute(img2, kernel1, 1);
  //img2 = convolute(img2, kernel2, 1);
  //img2 = convolute(img2, sobel, 1);
  img2 = convolute(img2, gaussianKernel);
  img2 = scharr(img2);

  img2.updatePixels();
  image(img2, img.width, 0);
}

void useThresholdBars() {
  thresholdBar1.display();
  thresholdBar1.update();
  thresholdBar2.display();
  thresholdBar2.update();
  thresholdBar3.display();
  thresholdBar3.update();
  thresholdBar4.display();
  thresholdBar4.update();
  thresholdBar5.display();
  thresholdBar5.update();
  thresholdBar6.display();
  thresholdBar6.update();

  System.out.println("H : " + (int)(255*thresholdBar1.getPos()) + " " + (int)(255*thresholdBar2.getPos()));
  System.out.println("S : " + (int)(255*thresholdBar3.getPos()) + " " + (int)(255*thresholdBar4.getPos()));
  System.out.println("B : " + (int)(255*thresholdBar5.getPos()) + " " + (int)(255*thresholdBar6.getPos()));
}

PImage add(PImage i1, PImage i2) {
  //PImage result = createImage(i1.width, i1.height, ALPHA);
  PImage result = i1.copy();
  for (int i = 0; i < i1.width*i1.height; i++) {
    if (i2.pixels[i] != color(0)) {
      result.pixels[i] = i2.pixels[i];
    }
  }
  return result;
}

PImage scharr(PImage img) {
  float[][] vKernel = {
    { 3, 0, -3 }, 
    { 10, 0, -10 }, 
    { 3, 0, -3 } };
  float[][] hKernel = {
    { 3, 10, 3 }, 
    { 0, 0, 0 }, 
    { -3, -10, -3 } };

  PImage result = createImage(img.width, img.height, ALPHA);
  // clear the image
  for (int i = 0; i < img.width * img.height; i++) {
    result.pixels[i] = color(0);
  }
  float max=0;
  float[] buffer = new float[img.width * img.height];

  int N = hKernel.length;
  for (int x = 1; x < img.width-1; x++) {
    for (int y = 1; y < img.height-1; y++) {
      float sumH = 0;
      float sumV = 0;
      for (int i = x-N/2; i <= x+N/2; i++) {
        for (int j = y-N/2; j <= y+N/2; j++) {
          if (i >= 0 && i < img.width && j >= 0 && j < img.height) {
            sumH += brightness(img.pixels[j*img.width+i]) * hKernel[j-(y-N/2)][i-(x-N/2)];
            sumV += brightness(img.pixels[j*img.width+i]) * vKernel[j-(y-N/2)][i-(x-N/2)];
          }
        }
      }
      float sum = (float) Math.sqrt(sumH * sumH + sumV * sumV);
      buffer[y * img.width + x] = sum;
      max = Math.max(max, sum);
    }
  }

  for (int y = 1; y < img.height - 1; y++) { // Skip top and bottom edges
    for (int x = 1; x < img.width - 1; x++) { // Skip left and right
      int val = (int) ((buffer[y * img.width + x]/max) * 255);
      result.pixels[y * img.width + x] = color(val);
    }
  }
  return result;
}

private float sum(float[][] kernel) {
  float sum = 0;
  for (int i = 0; i < kernel.length; i++) {
    for (int j = 0; j < kernel[0].length; j++) {
      sum+= kernel[i][j];
    }
  }
  return sum;
}

PImage convolute(PImage img, float[][] kernel) {
  PImage result = createImage(img.width, img.height, ALPHA);
  int N = kernel.length;
  float normFactor = Math.max(sum(kernel), 1);

  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      float sum = 0;
      for (int i = x-N/2; i <= x+N/2; i++) {
        for (int j = y-N/2; j <= y+N/2; j++) {
          if (i >= 0 && i < img.width && j >= 0 && j < img.height) {
            //sum += img.pixels[j*img.width+i] * kernel[j-(y-N/2)][i-(x-N/2)];
            sum += brightness(img.pixels[j*img.width+i]) * kernel[j-(y-N/2)][i-(x-N/2)];
          }
        }
      }
      int val = (int) (sum/normFactor);
      result.pixels[y * img.width + x] = color(val, val, val);
    }
  }
  return result;
}


boolean imagesEqual(PImage img1, PImage img2) {
  if (img1.width != img2.width || img1.height != img2.height)
    return false;
  for (int i = 0; i < img1.width*img1.height; i++)
    //assuming that all the three channels have the same value
    if (red(img1.pixels[i]) != red(img2.pixels[i]))
      return false;
  return true;
}

PImage thresholdHSB(PImage img, int minH, int maxH, int minS, int maxS, int minB, int maxB) {
  PImage result = createImage(img.width, img.height, RGB);
  for (int i = 0; i < img.width * img.height; i++) {
    float h = hue(img.pixels[i]);
    float s = saturation(img.pixels[i]);
    float b = brightness(img.pixels[i]);
    boolean criterion = s >= minS && s <= maxS && b >= minB && b <= maxB;
    if (!criterion) {
      result.pixels[i] = color(0, 0, 0);
    } else {
      if (minH <= maxH) {
        if (h >= minH && h <= maxH)
          result.pixels[i] = color(255, 255, 255);
        else
          result.pixels[i] = color(0, 0, 0);
      } else {
        if (h >= minH || h <= maxH)
          result.pixels[i] = color(255, 255, 255);
        else
          result.pixels[i] = color(0, 0, 0);
      }
    }
  }
  return result;
}

PImage selectHuesIn(PImage img, float minHueValue, float maxHueValue) {
  PImage result = createImage(img.width, img.height, RGB);
  for (int i = 0; i < img.width * img.height; i++) {
    float h = hue(img.pixels[i]);
    if (h >= minHueValue && h <= maxHueValue)
      result.pixels[i] = img.pixels[i];
    else
      result.pixels[i] = color(0, 0, 0);
  }
  return result;
}

PImage hueMap(PImage img) {
  PImage result = createImage(img.width, img.height, RGB);
  for (int i = 0; i < img.width * img.height; i++) {
    float h = hue(img.pixels[i]);
    result.pixels[i] = color(h, h, h);
  }
  return result;
}

void halfGreen(PImage img) {
  for (int x = 0; x < img.width; x++)
    for (int y = 0; y < img.height; y++)
      if (y%2==0)
        img.pixels[y*img.width+x] = color(0, 255, 0);
}

PImage threshold(PImage img, int threshold, boolean invert) {
  int inv = 1;
  if (invert) inv = -1;
  PImage result = createImage(img.width, img.height, RGB);
  for (int i = 0; i < img.width * img.height; i++) {
    if (inv * brightness(img.pixels[i]) >= inv * threshold) {
      result.pixels[i] = color(255, 255, 255);
    } else {
      result.pixels[i] = color(0, 0, 0);
    }
  }
  return result;
}

PImage truncate(PImage img, int threshold) {
  PImage result = createImage(img.width, img.height, RGB);
  for (int i = 0; i < img.width * img.height; i++) {
    if (brightness(img.pixels[i]) >= threshold) {
      result.pixels[i] = color(threshold, threshold, threshold);
    } else {
      result.pixels[i] = img.pixels[i];
    }
  }
  return result;
}
