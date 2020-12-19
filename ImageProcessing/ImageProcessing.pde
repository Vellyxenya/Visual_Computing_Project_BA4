import java.util.List;

PImage img, img2, img3;

BlobDetection bd;
HoughTransform hf;
QuadGraph qg;

HScrollbar h1 = new HScrollbar(0, width-20, 200, 20);

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

void settings() {
  size(1600, 600);
}

void setup() {
  img = loadImage("8.png");

  //surface.setSize((int)img.width*3/2, (int)img.height);
  surface.setSize((int)img.width*7/2, (int)img.height + 100);

  bd = new BlobDetection();
  hf = new HoughTransform();
  qg = new QuadGraph();

  //noLoop();
}

void draw() { 
  image(img, 0, 0);                                                  // The original board
  img2 = img.copy();
  img2.loadPixels();

  findBoard();

  img2.updatePixels();
  image(img2, img.width, 0, img2.width/2, img2.height/2);            // The board contour
  img3.updatePixels();
  image(img3, img.width, img.height/2, img3.width/2, img3.height/2); // The board blob
  
  h1.update();
  h1.display();
}

void findBoard() {
  int param = (int) (h1.getPos() * 255);
  //img2 = thresholdHSB(img2, 80, 145, 25, 255, 60, 255);
  img2 = thresholdHSB(img2, 80, 145, param, 255, 60, 255); //works much better for bad quality video
  System.out.println("param : " + param);
  img2 = convolute(img2, gaussianKernel);
  img2 = bd.findConnectedComponents(img2, true, color(0, 255, 0));
  img3 = img2.copy();
  img2 = scharr(img2);

  List<PVector> lines = hf.hough(img2, false, 4);
  displayLines(lines);
  if (lines.size() >= 4) {
    //displayLines(lines);
    List<PVector> quads = qg.findBestQuad(lines, img2.width, img2.height, img2.width*img2.height, 40*20, false);
    if (quads.size() >= 4) {
      displayQuads(quads);
      List<PVector> homogeneousQuads = new ArrayList<PVector>();
      for (PVector quad : quads) {
        homogeneousQuads.add(homogeneous3DPoint(quad));
      }
    }
  }
}

PVector homogeneous3DPoint(PVector p) {
  return new PVector(p.x, p.y, 1);
}

void displayQuads(List<PVector> quads) {
  for (PVector vect : quads) {
    float radius = 15;
    fill(104, 96, 237);
    stroke(255, 0, 0);
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

PImage add(PImage i1, PImage i2) {
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
