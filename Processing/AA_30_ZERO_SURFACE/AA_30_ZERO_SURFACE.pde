// 3D visualization for SWR measurements 
// For RigExpert AA-30 ZERO antenna & cable analyzer with Arduino Uno
//
// Receives data from AA-30 ZERO and makes a surface
// which is a visualization of SWR as a function of time
//
// 26 June 2017, Rig Expert Ukraine Ltd.
//
import processing.serial.*; 
 
Serial ZERO;    
int step;              // Communication protocol steps (0 - set Freq; 1 - set Range; 2 - start measurements)

int maxSamples = 100;  // Number of point to measure
int maxSets = 50;      // Time depth
float points[][];      // Measurements data
int sample;            // current sample
int set;               // current data set 
int colors[];          // curve color
int total;             // total samples acquired 
boolean ready;         // screen redrawn if True  
int Frequency;         // current Frequensy 
int Range;             // current Range  


// Code to send command to Analyzer 
void serialize(String cmd) {
  int len = cmd.length();
  int charPos = 0;
  while (len-- != 0) {
    ZERO.write(cmd.charAt(charPos));
    charPos++;
  }
}
 
// SWR computation function
// Z0 - System impedance (i.e. 50 for 50 Ohm systems)
// R - measured R value
// X - measured X value
float computeSWR(float Z0, float R, float X)
{
  float SWR, Gamma;
  float XX = X * X;                        
  float denominator = (R + Z0) * (R + Z0) + XX;
  if (denominator == 0) {
    return 1E9;
  } else {
    float l = (R - Z0) * (R - Z0);
    float t = (l + XX);
    t = t / denominator;
    Gamma = sqrt(t);    // always >= 0
    // NOTE:
    // Gamma == -1   complete negative reflection, when the line is short-circuited
    // Gamma == 0    no reflection, when the line is perfectly matched
    // Gamma == +1   complete positive reflection, when the line is open-circuited
    if (Gamma == 1.0) {
      SWR = 1E9;
    } else {
      SWR = (1 + Gamma) / (1 - Gamma);
    }
  }

  // return values
  if ((SWR > 200) || (Gamma > 0.99)) {
    SWR = 200;
  } else if (SWR < 1) {
    SWR = 1;
  }
  return SWR;
}

void setup() { 
  Frequency = 115000000;
  Range = 230000000;
  sample = 0;
  set = -1;
  step = 0;
  points = new float[maxSets + 1][maxSamples + 1];
  colors = new int[maxSets + 1];
  ready = false;
  total = 0;

  
  background(0);
  stroke(120, 240, 255, 255);
  strokeWeight(1);
  size(640, 480, P3D); 
  
  printArray(Serial.list()); 
  // Replace COM name with one that matches your conditions
  ZERO = new Serial(this, "COM21", 38400);
  ZERO.bufferUntil(13); 
  delay(1000);
  serialize("SW0\r\n");
} 


void drawSurface() {
    ready = false;
    lights();  
    float sp = 0.001 * frameCount;
    camera((width / 3) * sin(sp), 0, 800, width / 2, height / 2, 0, 0, 1, 0); 
    
    background(0, 0, 0);
    textSize(30);
    fill(255, 255, 255);
    // ---------------- Axis ---------------------
    stroke(255, 255, 255, 128);
    line(0, height, 0, width, height, 0);

    line(0, 0, 0, 0, height, 0);
    line(width, 0, 0, width, height, 0);
    
    line(0, height, 5 * maxSets, 0, height, 0);
    line(width / 2, height, 5 * maxSets, width / 2, height, 0);
    line(width, height, 5 * maxSets, width, height, 0);
    
    // ---------------- Freq. markers ----------------
    stroke(255, 255, 255, 128);
    line(width / 2, 0, 0, width / 2, height, 0);
    textAlign(CENTER);
    text(Frequency / 1E3 + " kHz", width / 2, height, 5 * maxSets);
    text(((Frequency / 1E3) - (Range / 2E3)) + " kHz", 0, height, 5 * maxSets);
    text(((Frequency / 1E3) + (Range / 2E3)) + " kHz", width, height, 5 * maxSets);
    
    // ----------------- Mode title ------------------
    textAlign(LEFT);
    textSize(36);
    text("SWR as a function of time Graph", 0, -100, 0);
    textSize(30);
    if (mouseY < height / 5) {
      if (mouseX < width / 2) {
        fill(255, 0, 0);
        textAlign(RIGHT);
        text("F = " + Frequency / 1E3 + " kHz", width / 2 - 50, -50, 0);
        fill(255, 255, 255);
        textAlign(LEFT);
        text("Range = " + Range / 1E3 + " kHz", width / 2 + 50, -50, 0);
      } else {
        fill(255, 255, 255);
        textAlign(RIGHT);
        text("F = " + Frequency / 1E3 + " kHz", width / 2 - 50, -50, 0);
        fill(255, 0, 0);
        textAlign(LEFT);
        text("Range = " + Range / 1E3 + " kHz", width / 2 + 50, -50, 0);
      }
    } else {
      fill(255, 255, 255);
      textAlign(RIGHT);
      text("F = " + Frequency / 1E3 + " kHz", width / 2 - 50, -50, 0);
      textAlign(LEFT);
      text("Range = " + Range / 1E3 + " kHz", width / 2 + 50, -50, 0);
    }
    
    // Get extremums
    float minV = 1E9;
    float maxV = -1E9;
    for (int i = 0; i < set; i++) {
      for (int j = 0; j < maxSamples + 1; j++) {
          if (points[i][j] > maxV) maxV = points[i][j];
          if (points[i][j] < maxV) minV = points[i][j];
      }
    }

    println("Min = " + minV + "; Max = " + maxV);
    minV = 1;
    if (maxV < 2) maxV = 2; 
    else if (maxV < 5) maxV = 5;
    else if (maxV < 10) maxV = 10;
    else maxV = 100;
    float hK = width / maxSamples;
    float vK = height / (maxV - minV);
    float zK = 2;
    
    
    // ----------------- Draw horizontal markers -----------------
    fill(255, 255, 255);
    textAlign(RIGHT);
    line(0, height - vK, 0, width, height - vK, 0);            // SWR = 2
    text("SWR = 2.0", 0, height - vK, 0);
    line(0, height - 2 * vK, 0, width, height - 2 * vK, 0);    // SWR = 3
    text("SWR = 3.0", 0, height - 2 * vK, 0);
    line(0, height - 4 * vK, 0, width, height - 4 * vK, 0);    // SWR = 5
    text("SWR = 5.0", 0, height - 4 * vK, 0);
    
    
    // Plot the lines
    for (int i = 0; i < set; i++) {
      if (colors[i] % 5 == 0) stroke(255, 0, 0, 255 * i / set);
      else stroke(120, 240, 255, 255 * i / set);

      for (int j = 1; j < maxSamples + 1; j++) {
        // draw only if SWR < 100.0
        if (points[i][j - 1] < 100) { 
          line((j - 1) * hK, height - (points[i][j - 1] - 1) * vK, i * zK, 
              j * hK, height - (points[i][j] - 1) * vK, i * zK);
        }
      }
    }
}


void draw() { 
  if (ready) {
    drawSurface();
  }
} 


// Process incoming data
void serialEvent(Serial p) { 
  String inString;  
  inString = p.readString(); 
  if (inString.indexOf("OK") >= 0) {   
    switch (step) {
      case 0: serialize("FQ" + Frequency + "\r\n");
              step = 1;
              break;
              
      case 1: serialize("SW" + Range + "\r\n");
              step = 2;
              break;
              
      case 2: serialize("FRX"+ str(maxSamples) + "\r\n");
              step = 0;
              sample = 0;
              if (set == maxSets) {
                // shift curves back  
                for (int i = 1; i < maxSets + 1; i++) {
                  colors[i - 1] = colors[i];
                  for (int j = 0; j < maxSamples + 1; j++) {
                    points[i - 1][j] = points[i][j];
                  }
                }
              } else {
                set++;
              }
              colors[set] = total++;
              ready = true;              
              break;
    }
    
  } else {
      float[] nums = float(split(inString, ','));
      if (nums.length == 3) {
        float SWR = computeSWR(50, nums[1], nums[2]);
        points[set][sample] = SWR;      
        sample++;
      }
  }
} 

// Change Frequency & Range values by the Mouse Wheel
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (mouseY < height / 5) {
    if (mouseX < width / 2) {
      // Change Freq.
      if (Frequency > 1E5) {
        Frequency += e * 100000;
        drawSurface();  
      }
    } else {
      // Change Range
      if (Range > 1E5) {
        Range += e * 1E5;
        drawSurface();
      }
    }
  }
}