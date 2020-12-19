import java.util.Collections;

import static java.lang.Math.cos;

class HoughTransform {

  int accumulator[];
  int phiDim;
  int rDim;

  //****** Parameters ******
  //params for image with original size
  //float discretizationStepsPhi = 0.01f;
  float discretizationStepsPhi = 0.01;
  float discretizationStepsR = 1.4f;
  int minVotes = 70;

  //params for image with half size
  /*float discretizationStepsPhi = 0.05f;
   float discretizationStepsR = 0.8f;
   int minVotes = 80;*/

  float[] tabSin, tabCos;

  public HoughTransform() {
    phiDim = (int) (Math.PI / discretizationStepsPhi +1);
    tabSin = new float[phiDim];
    tabCos = new float[phiDim];

    float ang = 0;
    float inverseR = 1.f / discretizationStepsR;
    for (int accPhi = 0; accPhi < phiDim; ang += discretizationStepsPhi, accPhi++) {
      tabSin[accPhi] = (float) (Math.sin(ang) * inverseR);
      tabCos[accPhi] = (float) (Math.cos(ang) * inverseR);
    }
  }

  List<PVector> hough(PImage edgeImg, boolean display, int nLines) {
    display = true;
    nLines = 4;
    //The max radius is the image diagonal, but it can be also negative
    rDim = (int) ((sqrt(edgeImg.width*edgeImg.width + edgeImg.height*edgeImg.height) * 2) / discretizationStepsR +1);

    int[] accumulator = new int[phiDim * rDim];
    for (int y = 0; y < edgeImg.height; y++) {
      for (int x = 0; x < edgeImg.width; x++) {
        if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) { // Are we on an edge?
          float phi = 0;
          int i = 0;
          while (phi < Math.PI) {
            int rIndex = (int) (x * tabCos[i] + y * tabSin[i] + rDim/2);
            int phiIndex = i++;
            accumulator[phiIndex * rDim + rIndex] += 1;
            phi += discretizationStepsPhi;
          }
        }
      }
    }

    List<Integer> bestCandidates = new ArrayList<Integer>();
    int N = 20;
    for (int rIndex = 0; rIndex < rDim; rIndex++) {
      for (int phiIndex = 0; phiIndex < phiDim; phiIndex++) {
        int val = accumulator[phiIndex * rDim + rIndex];
        if (val > minVotes) {
          boolean maximum = true;
          boolean show = false;
          if (rIndex == 639 && phiIndex == 29) {
            show = true;
          }
          for (int i = rIndex-N/2; i <= rIndex+N/2; i++) {
            for (int j = phiIndex-N/2; j <= phiIndex+N/2; j++) {
              if (show) {
                System.out.print(accumulator[j * rDim + i] + " ");
              }
              if (i >= 0 && i < rDim && !(i == rIndex && j == phiIndex)) {
                int iPrime = i;
                int jPrime = j;
                if (j < 0 || j >= phiDim) {
                  jPrime = Math.abs(phiDim - Math.abs(j));
                  iPrime = Math.abs(rDim - Math.abs(i));
                }
                if (accumulator[jPrime * rDim + iPrime] >= val) {
                  if (accumulator[jPrime * rDim + iPrime] > val || bestCandidates.contains(jPrime * rDim + iPrime)) {
                    maximum = false;
                  }
                }
              }
            }
          }
          if (maximum) {
            bestCandidates.add(phiIndex * rDim + rIndex);
            System.out.println("("+rIndex+", "+phiIndex+", val : "+val+")");
          }
        }
      }
    }

    if (display) {
      PImage houghImage = createImage(rDim, phiDim, ALPHA);
      for (int i = 0; i < accumulator.length; i++) {
        houghImage.pixels[i] = color(min(255, accumulator[i]), 0, 0);
        if (accumulator[i] >= minVotes) {
          houghImage.pixels[i] = color(0, 255, 0);
        }
      }
      //System.out.println(rDim);
      //houghImage.resize(600, 400);
      houghImage.updatePixels();
      image(houghImage, 600, 0);
    }

    Collections.sort(bestCandidates, new HoughComparator(accumulator));

    List<PVector> finalCandidates = new ArrayList<PVector>();
    for (int i = 0; i < nLines && i < bestCandidates.size(); i++) {
      int idx = bestCandidates.get(i);
      int accPhi = (int) (idx / (rDim));
      int accR = idx - (accPhi) * (rDim);
      float r = (accR - (rDim) * 0.5f) * discretizationStepsR;
      float phi = accPhi * discretizationStepsPhi;

      System.out.println("final("+r+", "+phi+")");

      finalCandidates.add(new PVector(r, phi));
    }

    return finalCandidates;
  }

  class HoughComparator implements java.util.Comparator<Integer> {
    int[] accumulator;

    public HoughComparator(int[] accumulator) {
      this.accumulator = accumulator;
    }

    @Override
      public int compare(Integer i1, Integer i2) {
      if (accumulator[i1] > accumulator[i2] || accumulator[i1] == accumulator[i2] && i1 < i2) return -1;
      return 1;
    }
  }
}
