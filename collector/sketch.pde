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
  int  count;                 // keep track of the last update
  u32  out_face;              // the immediate face through which to send data back
  char path[MAX_DIST];        // the path back to the central scrutinizer
  void report(int value) {
    facePrintf(out_face, "R%#p %d", path, count);
  }
};
Collector collector;          // my data collection information

void noticeCollector(u8 * packet) {
  int count;
  char dir;
  if (packetScanf(packet, "c%d %#p\n", &count, &path) != 3) {
    pprintf("L bad '%#p'\n",packet);
    return;
  }
  if (count > collector.count) {
    int path_ind = 0;
    char ch;
    // extract the return path 
    while(packetScanf(packet, "%c", &ch)) {
      collector.path[path_ind] = ch;
      ++path_ind;
    }
    colelctor.path[path_ind] = '\0';
    collector.count = count;
    collector.out_face = packetSource(packet);
    // collector.path = path;
    for (u32 f = NORTH; f <= WEST; ++f) {
      if (! collector.out_face == f) {
        // print to each face appending the new direction l, r, or f to the path
        // direction = out - in mod 4
        switch ((f - collector.out_face) % 4) {
        case 1: dir = 'l'; break;
        case 2: dir = 'f'; break;
        case 3: dir = 'r'; break;
        default: pprintf(" L hork %d to %d\n", collector.out_face, f); return;
        }
        facePrintf(f, "c%d %#p%c\n", count, path, dir);
      }
    }
    facePrintf(collector.out_face, "L noticed you at %s\n", path);
  }
}

void setup() {
  Body.reflex('c', noticeCollector);
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_GREEN_PIN);
}


#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)   // [Optional: Code number representing you]
#define SFB_SKETCH_PROGRAM_ID B36_3(c,o,l)   // [Optional: Code number representing this sketch]
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3" // [Optional: Copyright information string]
