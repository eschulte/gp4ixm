/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Mechanisms for collecting data from a group of
 *   IXM boards are irregular intervals
 *
 * Sketch author: Eric Schulte
 *
 */
#define MAX_DIST 100
int ident;

struct Collector {
  bool initialized;
  int  count;                 // keep track of the last update
  u32  out_face;              // the immediate face through which to send data back
  char path[MAX_DIST];        // the path back to the central scrutinizer
  void report(int val);       // reporting string "Rd1Rd2Rd3Rd4cvalue d4d3d2d1\n"
  void reset() {
    initialized = false;
    count = 0;
    out_face = 0;
    path[0] = '\0';
  }
};
Collector collector;

char reverseStep(char step) {
  switch(step) {
    case 'f': return 'f';
    case 'l': return 'r';
    case 'r': return 'l';
    default:  pprintf("L hork on %c\n", step); return 'z';
    }
}

// reporting string "Rd1Rd2Rd3Rd4cvalue d4d3d2d1\n"
void Collector::report (int val) {
  if (initialized) {
    int ind = 0;
    while(path[ind] != '\0') ++ind;       // rewind to the end of the string
    while(ind > 0) {                      // then step back to front building an R packet
      --ind; facePrintf(out_face, "R%c", reverseStep(path[ind]));
    }
    facePrintf(out_face, "c%d ", val);    // print out our value
    while(path[ind] != '\0') {            // then step back to the end recording position
      facePrintf(out_face, "%c", path[ind]); ++ind;
    }
    facePrintf(out_face, "\n");           // end the packet
  }
}

// called when recieving a collector notification packet 'c'
//
// if a new update (count > collector.count) this will update
// collector information and inform neighbors
void noticeCollector(u8 * packet) {
  int count;
  char dir;
  int in;
  int out;
  if (packetScanf(packet, "c%d ", &count) != 3) {
    pprintf("L bad '%#p'\n",packet);
    return;
  }
  if (count > collector.count) {
    collector.initialized = true;
    // pprintf("L initializing!\n");
    collector.count = count;
    collector.out_face = packetSource(packet);
    int path_ind = 0;
    char ch;
    // extract the return path
    while(packetScanf(packet, "%c", &ch)) {
      collector.path[path_ind] = ch;
      ++path_ind;
    }
    collector.path[path_ind] = '\0';
    // pprintf("L initialized to out %d path %s\n", collector.out_face, collector.path);
    // send on to neighbors
    for (u32 f = NORTH; f <= WEST; ++f) {
      if (collector.out_face != f) {
        // swap around south and east so that our modulo directions work
        if (collector.out_face == 1)      in = 2;
        else if (collector.out_face == 2) in = 1;
        else                              in = collector.out_face;
        if (f == 1)                       out = 2;
        else if (f == 2)                  out = 1;
        else                              out = f;
        switch ((4 + out - in) % 4) {                                     // find the dir l, r, or f
        case 1: dir = 'l'; break;
        case 2: dir = 'f'; break;
        case 3: dir = 'r'; break;
        default: pprintf(" L hork %d to %d is %d\n", in, out, ((4 + out - in) % 4)); return;
        }
        // pprintf("L c%d %s%c to %d\n", count, collector.path, dir, f); // debugging
        facePrintf(f, "c%d %s%c\n", count, collector.path, dir);      // append dir and send onward
      }
    }
  }
}

void setup() {
  ident = random(100);                  // my unique identity
  collector.initialized = false;        // is not yet initialized
  Body.reflex('c', noticeCollector);    // collector notification packets 'c'
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);
  collector.report(ident);
}


#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)   // [Optional: Code number representing you]
#define SFB_SKETCH_PROGRAM_ID B36_3(c,o,l)   // [Optional: Code number representing this sketch]
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3" // [Optional: Copyright information string]
