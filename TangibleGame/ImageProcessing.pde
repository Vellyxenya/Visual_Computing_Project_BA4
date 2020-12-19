import processing.video.*; //<>//
import java.util.List;

Movie movie;
PImage img;

OpenCV opencv;
BlobDetection bd;
HoughTransform hf;
QuadGraph qg;
TwoDThreeD td3d;

PVector rotation = new PVector(0, 0, 0);

private static final String TEST_VIDEO_NAME = "testvideo.avi";
private static final int VIDEO_WIDTH = 480;
private static final int VIDEO_HEIGHT = 270;

KalmanFilter2D kfs[] = new KalmanFilter2D[4];

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

class ImageProcessing extends PApplet {

  void settings() {
    size(VIDEO_WIDTH, VIDEO_HEIGHT);
    initCapture();
  }

  void setup() {
    for (int i = 0; i < 4; i++) {
      kfs[i] = new KalmanFilter2D();
    }
  }

  void draw() {
    captureCamera();
    findBoard(img);
  }

  void captureCamera() {
    if (simulate) {
      movie.play();
      if (movie.available() == true) {
        movie.read();
      }
      img = movie.get();
      img.resize(img.width/2, img.height/2);
      image(img, 0, 0);
    } else {
      movie.pause(); 
    }
  }

  void findBoard(PImage img) {
    img = thresholdHSB(img, 80, 145, 20, 255, 60, 255);
    //img = convolute(img2, gaussianKernel); // disable for performance (also seems quite useless)
    img = bd.findConnectedComponents(img, true, color(0, 255, 0));
    img = scharr(img);

    List<PVector> lines = hf.hough(img, false, 4);

    if (lines.size() >= 4) {
      List<PVector> quads = qg.findBestQuad(lines, img.width, img.height, img.width*img.height, 50*25, false);
      displayLines(lines);
      if (quads.size() >= 4) {
        PVector kfHats[] = new PVector[4];
        PVector finalQuads[] = new PVector[4];
        for (int i = 0; i < 4; i++) {
          kfHats[i] = kfs[i].vectorHat();
          finalQuads[i] = quads.get(i);
        }
        for (int j = 0; j < 4; j++) {
          float minDistance = Float.MAX_VALUE;
          for (int i = 0; i < quads.size(); i++) {
            float distance = squaredDistance(kfHats[j], quads.get(i));
            if (distance < minDistance) {
              minDistance = distance;
              finalQuads[j] = quads.get(i);
            }
          }
          quads.remove(finalQuads[j]);
        }

        List<PVector> correctedQuads = new ArrayList<PVector>();
        for (int i = 0; i < 4; i++) {
          correctedQuads.add(kfs[i].predict_and_correct(finalQuads[i]));
        }

        displayQuads(correctedQuads, color(100, 170, 255));

        List<PVector> homogeneousQuads = new ArrayList<PVector>();
        for (PVector quad : correctedQuads) {
          homogeneousQuads.add(homogeneous3DPoint(quad));
        }
        List<PVector> permutedHomogeneous = new ArrayList<PVector>();
        permutedHomogeneous.add(homogeneousQuads.get(0));
        permutedHomogeneous.add(homogeneousQuads.get(2));
        permutedHomogeneous.add(homogeneousQuads.get(3));
        permutedHomogeneous.add(homogeneousQuads.get(1));
        rotation = td3d.get3DRotations(permutedHomogeneous);
      } else {
        List<PVector> predictedQuads = new ArrayList<PVector>();
        for (int i = 0; i < 4; i++) {
          kfs[i].predict();
          predictedQuads.add(kfs[i].vectorHat());
        }
        displayQuads(predictedQuads, color(255, 0, 0));
      }
    }
  }

  float squaredDistance(PVector v1, PVector v2) {
    PVector diff = v1.copy().sub(v2);
    return diff.x*diff.x + diff.y*diff.y;
  }

  void displayQuads(List<PVector> quads, color c) {
    for (PVector vect : quads) {
      float radius = 10;
      fill(c);
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
      stroke(0, 255, 0);
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
}

void initCapture() {
  movie = new Movie(this, TEST_VIDEO_NAME);
  movie.loop();
  movie.volume(0);
  movie.speed(1);
}

PVector getRotation() {
  return rotation;
}

PVector homogeneous3DPoint(PVector p) {
  return new PVector(p.x, p.y, 1);
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
  int th = N/2;
  for (int x = 1; x < img.width-1; x++) {
    for (int y = 1; y < img.height-1; y++) {
      float sumH = 0;
      float sumV = 0;
      for (int i = x-th; i <= x+th; i++) {
        for (int j = y-th; j <= y+th; j++) {
          if (i >= 0 && i < img.width && j >= 0 && j < img.height) {
            sumH += brightness(img.pixels[j*img.width+i]) * hKernel[j-(y-th)][i-(x-th)];
            sumV += brightness(img.pixels[j*img.width+i]) * vKernel[j-(y-th)][i-(x-th)];
          }
        }
      }
      float squaredSum = sumH * sumH + sumV * sumV;
      buffer[y * img.width + x] = squaredSum;
      max = Math.max(max, squaredSum);
    }
  }

  max = (int) Math.sqrt(max);

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
