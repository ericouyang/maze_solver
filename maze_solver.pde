/* 
 * Maze Solver - ver 1.0 - Eric Ouyang
 *
 * COMP-630 Final Project
 * 3/11/2013
 *
 * This is a visual program that allows the user to draw an arbitrary maze and find the shortest paths through that maze
 * After a start point is indicated, the paths from that point can be calculated using a variation of Dijkstra's algorithm
 * An optional end point can be indicated to stop the program after a path is found
 * Alternatively, the program will just calculate all possible paths.
 * The distance between the start and that point is indicated with a mix of blue (closest) and green (furthest)
 * Using a recursive function, the path between that start point to an end point is calculated and visualized
 *
 * INSTRUCTIONS:
 * Draw maze by clicking and dragging.
 * To set the start point, press and hold 's' and click the desired position
 * To set an (optional) end point, press and hold 'e' and click the desired position
 * To clear the board, click 'c'
 * To start calculations, click on the space bar - you may now no longer continue drawing the maze
 * To pause calculations, click on the space bar while the program is running
 * Once a path to a point has been calculated (has been shaded blue/green), you can find the path between the start
 *   and that path by pressing and holding 'e' and clicking on that position - this can be done while calculations are running
 * NOTE: You cannot restart calculations after a path is found to an initially indicated end point
 *
 * Referenced Wikipedia article on Dijkstra's algorithm :http://en.wikipedia.org/wiki/Dijkstra's_algorithm
 * Processing API: http://processing.org/reference/
 */ 

private int startX, startY, endX, endY, currentX, currentY;

// minimum path length from (startX, startY) to (x, y)
private int[][] pathLengths;

// the function calcNextNode has been called for this (x, y)
private boolean[][] visited;

// is (x, y) in the path?
private boolean[][] inPath;

// the current list of points in the path between start to end
private ArrayList path;

// the pool of points that are candidates to be calculated next
private ArrayList edge;

// flags for coordinating the program
private boolean startSet, endSet, endFound, calculating, canDraw;

// constants
private final int EMPTY = 0, WALL = 1, START = 2, END = 3;
private final int STEP = 10;

/** BUILT-IN PROCESSING FUNCTIONS **/

// setup the Processing environment
void setup()
{
  size(1000, 1000);
  background(0);
  
  // initialize variables and flags
  startX = startY = endX = endY = currentX = currentY = 0;
  
  pathLengths = new int[width][height];
  visited = new boolean[width][height];
  
  edge = new ArrayList();
  
  canDraw = true;
  startSet = endSet = endFound = calculating = false;
  
  // surround the canvas with a wall
  drawWall();
    
  // fill pathLengths array with maximum value for integers
  // this is the indeterminate state for pathLengths - ie. the path has not been calcuated for that corresponding point
  for (int x = 0; x < width; x++)
    for (int y = 0; y < height; y++)
      pathLengths[x][y] = Integer.MAX_VALUE;   
}

// loop - shows the current process
void draw()
{
  if (calculating)
    calcNextNode();
}

// used for drawing the maze
void mouseDragged()
{
  if (canDraw)
    fillDotsBetween(pmouseX, pmouseY, mouseX, mouseY);
  
}

// set start and end points
void mouseClicked()
{
  noStroke();
  if (keyPressed == true)
  {
    // set start point
    if (key == 's' && !startSet)
    {
      println("Start point set to: (" + startX + ", " + startY + ")");
      
      startSet = true;
      
      // round to nearest STEP
      startX = mouseX / STEP * STEP;
      startY = mouseY / STEP * STEP;
      
      currentX = startX;
      currentY = startY;
      
      // this is the starting point - starting length of 0
      pathLengths[startX][startY] = 0;
      
      // draw point
      fill(0, 255, 0);
      ellipse(startX, startY, STEP, STEP);
    }
    // set end point
    else if (key == 'e')
    {
      println("End point set to: (" + endX + ", " + endY + ")");
      
      endSet = true;
      
      // round to nearest STEP
      endX = mouseX / STEP * STEP;
      endY = mouseY / STEP * STEP;
      
      // draw point
      fill(255, 0, 0);
      ellipse(endX, endY, STEP, STEP); 
      
      // if the pathLength has been calculated for this point, draw the path
      if (pathLengths[endX][endY] < Integer.MAX_VALUE)
        drawPath(endX, endY);
    }
  }
}

void keyPressed()
{
  if (key == ' ')
  {
    if (!calculating)
    {
      println("Calculating paths...");
      
      calculating = true;
      canDraw = false;
    }
    else
    {
      println("Calculating stopped...");
      
      calculating = false;
    }
  }
  else if (key == 'c')
  {
    println("Reset canvas");
    
    setup();
  }
}

/** PRIMARY FUNCTIONS **/

// calculates path lengts for the next smallest node
// originally implemented recursively, changed to non-recursive in order to display real-time calculations
// accomplished by storing the current x, y values and reading them, rather than passing it in recursively
void calcNextNode()
{
  visited[currentX][currentY] = true;

  for(int[] neighbor : getNeighbors(currentX,currentY))
  {
    // updated pathLengths and draw the point
    updateLocationValue(neighbor[0], neighbor[1], pathLengths[currentX][currentY]);
    
    if (endFound) // we found it -- all set!
    {
      calculating = false;
      println("End found!");
      drawPath(endX, endY);
      return;
    }
    
    // set this point as a potential candidate for the next iteration
    if (isValidLocation(neighbor[0], neighbor[1]) && getLocationType(neighbor[0], neighbor[1]) != WALL && !visited[neighbor[0]][neighbor[1]])
    {
      edge.add(neighbor);
      drawLocation(neighbor[0], neighbor[1]);
    }
  }
  
  if (edge.size() == 0)
  {
    println("No more paths");
    calculating = false;
    return;
  }
  
  // get next smallest point for next loop
  int smallestIndex = getSmallestIndex(edge);
  int[] smallest = (int[])edge.remove(smallestIndex);
  currentX = smallest[0];
  currentY = smallest[1];
}

// draw path from start to (x, y)
void drawPath(int x, int y)
{
  println("Calculating path...");
  
  // initialize path and inPath (clears out if previously calculated for another point)
  path = new ArrayList();
  inPath = new boolean[width][height];
  
  calcPath(x, y);
  
  // remove the first point, because this is the endpoint
  path.remove(0);
  
  // iterate through the path and draw the points
  for (Object o : path)
  {
    int[] node = (int[])o;
    noStroke();
    fill(255, 0, 255);
    ellipse(node[0],node[1],STEP,STEP);
  }
}

/** HELPER FUNCTIONS **/

// Recursive function to calcuate the path between (x, y) and (startX, startY)
void calcPath(int x, int y)
{
  if (x == startX && y == startY)
    return;
  inPath[x][y] = true;
  path.add(new int[]{x, y});
  int[] next = getSmallestNeighbor(x, y);
  calcPath(next[0], next[1]);
}

// fills all the dots (width of two dots) in between two given points
void fillDotsBetween(int x1, int y1, int x2, int y2)
{
  noStroke();
  fill(255);

  // round to nearest STEP
  x1 = x1 / STEP * STEP;
  y1 = y1 / STEP * STEP;
  x2 = x2 / STEP * STEP;
  y2 = y2 / STEP * STEP;
  
  // this if-elif chain is necessary to avoid division by zero and properly defined coordinates
  if (x2 > x1)
  {
    int slope = (y2 - y1) / (x2 - x1);
    for (int x = x1; x <= x2; x += STEP)
    {
      int y = slope * abs(x - x1) + y1;
      ellipse(x, y, STEP, STEP);
      ellipse(x, y+STEP, STEP, STEP);
    }
  }
  else if (y2 > y1)
  {
    int slope = (x2 - x1) / (y2 - y1);
    for (int y = y1; y <= y2; y += STEP)
    {
      int x = slope * abs(y - y1) + x1;
      ellipse(x, y, STEP, STEP);
      ellipse(x+STEP, y, STEP, STEP);
    }
  }
  else if (x1 > x2)
  {
    int slope = (y1 - y2) / (x1 - x2);
    for (int x = x2; x <= x1; x += STEP)
    {
      int y = slope * (x - x1) + y1;
      ellipse(x, y, STEP, STEP);
      ellipse(x, y+STEP, STEP, STEP);
    }
  }
  else if (y1 > y2)
  {
    int slope = (x1 - x2) / (y1 - y2);
    for (int y = y2; y <= y1; y += STEP)
    {
      int x = slope * (y - y1) + x1;
      ellipse(x, y, STEP, STEP);
      ellipse(x+STEP, y, STEP, STEP);
    }
  }
}

// draw a surrounding wall
void drawWall()
{
  noStroke();
  fill(255);
  for (int x = 0; x <= width; x += STEP)
    ellipse(x, 0, STEP, STEP);
  for (int x = 0; x <= width; x += STEP)
    ellipse(x, height, STEP, STEP);
  for (int y = 0; y <= height; y += STEP)
    ellipse(0, y, STEP, STEP);
  for (int y = 0; y <= height; y += STEP)
    ellipse(width, y, STEP, STEP);
}

// draw the point with given x, y with weighted color
void drawLocation(int x, int y)
{
  if (getLocationType(x,y) != WALL && getLocationType(x,y) != END)
  {
    noStroke();
    fill(0, getWeightedValue(x, y), 255 - getWeightedValue(x, y));
    ellipse(x,y, STEP, STEP);
  }
}

// update the location value and check if this is the end
void updateLocationValue(int x, int y, int prevValue)
{
  if (isValidLocation(x,y) && getLocationType(x,y) != WALL)
  {
    if (getLocationType(x,y) == END)
      endFound = true;
    if (prevValue + 1 < getLocationValue(x,y)) // if new value is less than old value, replace
    {
      pathLengths[x][y] = prevValue + 1;
    }
  }
}

// get the 8 neighbors - up, down, left, right, and diagonals
int[][] getNeighbors(int x, int y)
{
  int[][] neighbors = new int[8][2];
  
  neighbors[0] = new int[] {x, y-STEP};
  neighbors[1] = new int[] {x, y+STEP};
  neighbors[2] = new int[] {x+STEP, y};
  neighbors[3] = new int[] {x-STEP, y};
  
  neighbors[4] = new int[] {x-STEP, y-STEP};
  neighbors[5] = new int[] {x-STEP, y+STEP};
  neighbors[6] = new int[] {x+STEP, y-STEP};
  neighbors[7] = new int[] {x+STEP, y+STEP};
  
  return neighbors;
}

// is this within the boundaries of the window?
boolean isValidLocation(int x, int y)
{
  return x >= 0 && x < width && y >= 0 && y < height;
}

// what's the value of this location?
int getLocationValue(int x, int y)
{
  if(isValidLocation(x,y))
    return pathLengths[x][y];
  return Integer.MAX_VALUE;
}

// a weighted value of the current pathLength, used to visualize the paths
int getWeightedValue(int x, int y)
{
  if (!isValidLocation(x,y))
    return 0;
  return (int)constrain(map(pathLengths[x][y], 0, width / STEP, 0, 255), 0, 255); 
}

// returns the type id of the corresponding point (see constants)
int getLocationType(int x, int y)
{
  // rounds to nearest step
  x = x / STEP * STEP;
  y = y / STEP * STEP;
  
  if (!isValidLocation(x,y))
    return -1;
  
  loadPixels(); // load the pixels color values into the pixels variable
  
  // get the color of the corresponding pixel
  color c = pixels[y * width + x];
  
  if (c == color(0))
    return EMPTY; // empty
  else if (c == color(255))
    return WALL; // wall
  else if (c == color(0, 255, 0))
    return START; // start
  else if (c == color(255, 0, 0))
    return END; // end
  return -1;
}

// used in recursive path finding function - returs the smallest neighbor of (x, y)
int[] getSmallestNeighbor(int x, int y)
{
  int smallestNeighborValue = pathLengths[x][y];
  int[] smallestNeighbor = new int[2];
  
  for (int[] neighbor : getNeighbors(x,y))
  {
    int value = getLocationValue(neighbor[0], neighbor[1]);
    if (isValidLocation(neighbor[0], neighbor[1]) && !inPath[neighbor[0]][neighbor[1]] && value < smallestNeighborValue)
    {
      smallestNeighborValue = value;
      smallestNeighbor = neighbor;
    }
  }

  return smallestNeighbor;
}

// helper method to get the smallest index in an ArrayList of locations
int getSmallestIndex(ArrayList arr)
{
  int smallestValue = Integer.MAX_VALUE;
  int smallestIndex = 0;
  
  for (int i = 0; i < arr.size(); i++)
  {
    int[] n = (int[])arr.get(i);
    int value = getLocationValue(n[0], n[1]);
    if (isValidLocation(n[0], n[1]) && !visited[n[0]][n[1]] && value < smallestValue)
    {
      smallestValue = value;
      smallestIndex = i;
    }
  }
  
  return smallestIndex;
}
