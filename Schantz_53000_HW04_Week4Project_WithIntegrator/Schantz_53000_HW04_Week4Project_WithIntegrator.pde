// Set variables
PImage mapImage;
Table locationTable;
Table nameTable;
Table dataTable;
int rowCount;
int tablePointer = 1;
float dataMin = MAX_FLOAT;
float dataMax = MIN_FLOAT;

Integrator[] interpolators;

void setup( ) { // executes once
  size(640, 400);
  mapImage = loadImage("map.png");
  locationTable = new Table("locations.tsv"); // list of state abbreviations & there location coordinates
  nameTable = new Table("names.tsv"); // list of state abbreviations & names
  rowCount = locationTable.getRowCount( );
  PFont font = loadFont("Helvetica-Bold-12.vlw");
  textFont(font); // sets the current font
  smooth( );
  
  // Import initial-view's data
  dataTable = new Table("jackpot.tsv"); // Powerball jackpot winners by state
  // Find max & min values of data to plot
  for (int row = 0; row < rowCount; row++) {
    //float value = dataTable.getFloat(row, tablePointer);
    float value = dataTable.getFloat(row, 1);
    if (value > dataMax) {
      dataMax = value;
    }
    if (value < dataMin) {
      dataMin = value;
    }
  }
  
  // Load initial values into the Integrator
  interpolators = new Integrator[rowCount];
  for (int row = 0; row < rowCount; row++) {
    //float initialValue = dataTable.getFloat(row, tablePointer);
    float initialValue = dataTable.getFloat(row, 1);
    interpolators[row] = new Integrator(initialValue);
  }
}

// Global variables set in drawData() and read in draw()
float closestDist;
String closestText;
float closestTextX;
float closestTextY;

void draw( ) {
  background(255);
  image(mapImage, 0, 0);
  closestDist = MAX_FLOAT;
  
  // Update the Integrator with the current values, which are either those from the setup() function
  // or those loaded by the target() function issued in updateTable().
  for (int row = 0; row < rowCount; row++) {
    interpolators[row].update( );
  }
  
  for (int row = 0; row < rowCount; row++) {
    String abbrev = dataTable.getRowName(row);
    float x = locationTable.getFloat(abbrev, 1);
    float y = locationTable.getFloat(abbrev, 2);
    drawData(x, y, abbrev);
  }
  
  // Use global variables set in drawData() to draw text related to closest circle.
  if (closestDist != MAX_FLOAT) {
    fill(0);
    textAlign(CENTER);
    text(closestText, closestTextX, closestTextY);
  }
  drawTitle();
  drawSubTitle();
}

void drawTitle() {
  fill(0);
  textSize(12);
  textAlign(CENTER);
String title = "U.S. Lottery Return on Investment Statistics";
  text(title, width/2, 15);
}

void drawSubTitle() {
  fill(0);
  textSize(10);
  textAlign(CENTER);
  String subTitle;
  if (tablePointer == 1) {
    subTitle = "Powerball Jackpot Winners Since 1992";
  } else if (tablePointer == 2) {
    subTitle = "2018 Lottery Expense Per Capita";
  } else {
    subTitle = "Average Household Income (Thousands)";
  }
  text(subTitle, width/2, 30);
}

void drawData(float x, float y, String abbrev) {
  int row = dataTable.getRowIndex(abbrev); // determine row
  float value = interpolators[row].value; // get the current value
  
  // Create ellipses on map representing magnitude of value
  float radius = map(value, dataMin, dataMax, .5, 15);
  fill(68,34,204,153); // #4422CC blue at 60% opacity
  ellipseMode(RADIUS);
  ellipse(x, y, radius, radius);
  
  // Display values closest to the mouse
  float d = dist(x, y, mouseX, mouseY);
  if ((d < radius + 2) && (d < closestDist)) {
    closestDist = d;
    String name = nameTable.getString(abbrev, 1);
    if (tablePointer == 1) {
      closestText = name + " " + nf(value, 0, 0);
    } else {
      closestText = name + " $" + nf(value, 0, 2);
    }
    closestTextX = x;
    closestTextY = y-radius-4;
  }
}

// Update map display with keystroke
void keyPressed() {
  if (key == ' ') {
    tablePointer += 1;
    updateTable();
  }
}

void updateTable() {
  if (tablePointer == 2) {
    dataTable = new Table("lottery.tsv");
    // https://lendedu.com/blog/how-much-do-americans-spend-on-the-lottery/
  } else if (tablePointer == 3) {
    dataTable = new Table("avgincome.tsv");
    // https://www.kaggle.com/goldenoakresearch/us-household-income-stats-geo-locations
  } else { // toggle back to initial view
    dataTable = new Table("jackpot.tsv");
    //https://www.powerball.net/winners
    tablePointer = 1;
  }
  
  // Reset max & min variables for new dataset
  dataMin = MAX_FLOAT;
  dataMax = MIN_FLOAT;
  
  // Find new max & min values
  for (int row = 0; row < rowCount; row++) {
    float value = dataTable.getFloat(row, 1);
    if (value > dataMax) {
      dataMax = value;
    }
    if (value < dataMin) {
      dataMin = value;
    }
  }
  for (int row = 0; row < rowCount; row++) {
    //float newValue = random(dataMin, dataMax);
    float newValue = dataTable.getFloat(row, 1);
    interpolators[row].target(newValue);
  }
}
