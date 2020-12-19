import java.util.Collections;

import static java.lang.Math.cos;

class HoughTransform {

  int accumulator[];
  int phiDim;
  int rDim;
  
  //****** Parameters ******
  float discretizationStepsPhi = 0.009f;
  float discretizationStepsR = 2f;
  int minVotes = 300;
  
  float[] tabSin, tabCos;

  public HoughTransform() {
    phiDim = (int) (Math.PI / discretizationStepsPhi +1);
    tabSin = new float[phiDim];
    tabCos = new float[phiDim];
    
    float ang = 0;
    float inverseR = 1.f / discretizationStepsR;
    for(int accPhi = 0; accPhi < phiDim; ang += discretizationStepsPhi, accPhi++) {
      tabSin[accPhi] = (float) (Math.sin(ang) * inverseR);
      tabCos[accPhi] = (float) (Math.cos(ang) * inverseR);
    }
  
  }

  List<PVector> hough(PImage edgeImg, boolean display, int nLines) {
    //The max radius is the image diagonal, but it can be also negative
    rDim = (int) ((sqrt(edgeImg.width*edgeImg.width + edgeImg.height*edgeImg.height) * 2) / discretizationStepsR +1);

    int[] accumulator = new int[phiDim * rDim];
    for (int y = 0; y < edgeImg.height; y++) {
      for (int x = 0; x < edgeImg.width; x++) {
        if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) { // Are we on an edge?
          float phi = 0;
          int i = 0;
          while (phi < Math.PI) {
            int rIndex = (int) (x * tabCos[i] + y * tabSin[i++] + rDim/2);
            //int rIndex = (int) (r / discretizationStepsR);
            int phiIndex = (int) (phi / discretizationStepsPhi);
            accumulator[phiIndex * rDim + rIndex] += 1;
            phi += discretizationStepsPhi;
          }
        }
      }
    }
    
    List<Integer> bestCandidates = new ArrayList<Integer>();
    int N = 9;
    for (int rIndex = 0; rIndex < rDim; rIndex++) {
      for (int phiIndex = 0; phiIndex < phiDim; phiIndex++) {
        int val = accumulator[phiIndex * rDim + rIndex];
        if (val > minVotes) {
          boolean maximum = true;
          for (int i = rIndex-N/2; i <= rIndex+N/2; i++) {
            for (int j = phiIndex-N/2; j <= phiIndex+N/2; j++) {
              if (i >= 0 && i < rDim && j >= 0 && j < phiDim) {
                if (accumulator[j * rDim + i] > val) maximum = false;
              }
            }
          }
          if (maximum) {
            bestCandidates.add(phiIndex * rDim + rIndex);
          }
        }
      }
    }

    if (display) {
      PImage houghImage = createImage(rDim, phiDim, ALPHA);
      for (int i = 0; i < accumulator.length; i++) {
        houghImage.pixels[i] = color(min(255, accumulator[i]));
      }
      houghImage.resize(600, 400);
      houghImage.updatePixels();
      image(houghImage, 0, 0);
    }

    Collections.sort(bestCandidates, new HoughComparator(accumulator));

    List<PVector> finalCandidates = new ArrayList<PVector>();
    for (int i = 0; i < nLines; i++) {
      int idx = bestCandidates.get(i);
      int accPhi = (int) (idx / (rDim));
      int accR = idx - (accPhi) * (rDim);
      float r = (accR - (rDim) * 0.5f) * discretizationStepsR;
      float phi = accPhi * discretizationStepsPhi;
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
