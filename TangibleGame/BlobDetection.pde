import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Set;
import java.util.HashSet;
import java.util.Map;
import java.util.TreeSet;

class BlobDetection {

  private static final int NB_PRESET_COLORS = 10;
  private final color[] colors;

  public BlobDetection() {
    colors = new color[NB_PRESET_COLORS];
    colors[0] = color(255, 0, 0);
    colors[1] = color(0, 255, 0);
    colors[2] = color(0, 0, 255);
    colors[3] = color(255, 255, 0);
    colors[4] = color(0, 255, 255);
    colors[5] = color(255, 0, 255);
    colors[6] = color(255, 128, 128);
    colors[7] = color(128, 255, 128);
    colors[8] = color(128, 128, 255);
    for(int i = 9; i < NB_PRESET_COLORS; i++) {
      colors[i] = color(random(255), random(255), random(255));
    }
  }

  PImage findConnectedComponents(PImage input, boolean onlyBiggest, color fill) {
    int[] labels = new int[input.width*input.height];
    List<TreeSet<Integer>> labelsEquivalences = new ArrayList<TreeSet<Integer>>();

    //FIRST_PASS
    int currentLabel = 0;
    int N = 3;
    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        if (input.pixels[y*input.width+x] != color(0)) {
          int label = Integer.MAX_VALUE;
          TreeSet<Integer> equivs = new TreeSet<Integer>();
          for (int i = x-N/2; i <= x+N/2; i++) {
            for (int j = y-N/2; j <= y; j++) {  //<---Optimisation : y+N/2; j++) {
              if (i >= 0 && i < input.width && j >= 0 && j < input.height) {
                int newLabel = labels[j*input.width+i];
                if (newLabel != 0) {
                  equivs.add(newLabel);
                  label = Math.min(label, Math.min(newLabel, currentLabel));
                }
              }
            }
          }
          TreeSet<Integer> totalEquivs = new TreeSet<Integer>();
          for (int e : equivs)
            totalEquivs.addAll(labelsEquivalences.get(e-1));
          for (int e : equivs)
            labelsEquivalences.get(e-1).addAll(totalEquivs);
          if (label == Integer.MAX_VALUE) {
            labels[y*input.width+x] = ++currentLabel;
            TreeSet<Integer> newTreeSet = new TreeSet<Integer>();
            newTreeSet.add(currentLabel);
            labelsEquivalences.add(newTreeSet);
          } else {
            labels[y*input.width+x] = label;
          }
        }
      }
    }

    //SECOND_PASS
    int max = 0;
    int maxLabel = 0;
    List<Integer> finalLabels = new ArrayList<Integer>();
    List<Integer> count = new ArrayList<Integer>();
    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        int label = labels[y*input.width+x];
        if (label != 0) {
          TreeSet<Integer> gotten = labelsEquivalences.get(label-1);
          int assignedLabel = gotten.first();
          labels[y*input.width+x] = assignedLabel;
          if (!finalLabels.contains(assignedLabel)) {
            finalLabels.add(assignedLabel);
            count.add(0);
          } else {
            int index = finalLabels.indexOf(assignedLabel);
            int nb = count.get(index);
            if(++nb > max) {
              maxLabel = assignedLabel;
              max = nb;
            }
            count.set(index, nb);
          }
        }
      }
    }

    //OUTPUT
    PImage output = createImage(input.width, input.height, RGB);
    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        int label = labels[y*input.width+x];
        if(onlyBiggest) {
          output.pixels[y*input.width+x] = (label == maxLabel)? fill : color(0);
        } else {
          int index = finalLabels.indexOf(label);
          color c = (index >= 0 && index < NB_PRESET_COLORS)? colors[finalLabels.indexOf(label)] : color(random(255), random(255), random(255));
          output.pixels[y*input.width+x] = (label == 0)? color(0) : c;
        }
      }
    }
    return output;
  }
  
}
