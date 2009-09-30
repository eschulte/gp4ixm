/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Mechanisms for collecting data from a group of
 *   IXM boards are irregular intervals
 *
 * Sketch author: Eric Schulte
 *
 */

#define MAX_DIST 100

struct Collector {
  bool initialized;
  int  count;                 // keep track of the last update
  u32  out_face;              // the immediate face through which to send data back
  char path[MAX_DIST];        // the path back to the central scrutinizer
  // reporting string "Rd1Rd2Rd3Rd4cvalue d4d3d2d1\n"
  void report(int val) {
    if (initialized) {
      int ind = 0;
      while(path[ind] != '\0') {
        facePrintf(out_face, "R%c", path[ind]);
        ++ind;
      }
      facePrintf(out_face, "c%d ", val);
      while(ind > 0) {
        --ind;
        facePrintf(out_face, "%c", path[ind]);
      }
      facePrintf(out_face, "\n");
    }
  }
};
Collector collector;                  // my data collection information

void noticeCollector(u8 * packet) {
  int count;
  char dir;
  if (packetScanf(packet, "c%d ", &count) != 3) {
    pprintf("L bad '%#p'\n",packet);
    return;
  }
  if (count > collector.count) {
    collector.initialized = true;
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
    for (u32 f = NORTH; f <= WEST; ++f) {
      if (collector.out_face != f) {
        switch ((f+4 - collector.out_face) % 4) {                 // find the dir l, r, or f
        case 1: dir = 'l'; break;
        case 2: dir = 'f'; break;
        case 3: dir = 'r'; break;
        default: pprintf(" L hork %d to %d\n", collector.out_face, f); return;
        }
        facePrintf(f, "c%d %s%c\n", count, collector.path, dir);  // append dir and send onward
      }
    }
  }
}

void setup() {
  collector.initialized = false;        // is not yet initialized
  Body.reflex('c', noticeCollector);
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_GREEN_PIN);
  collector.report(random(100));
}


#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)   // [Optional: Code number representing you]
#define SFB_SKETCH_PROGRAM_ID B36_3(c,o,l)   // [Optional: Code number representing this sketch]
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3" // [Optional: Copyright information string]
