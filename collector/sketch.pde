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
    while(packetScanf(packet, "%c", &ch)) {       // extract the return path
      collector.path[path_ind] = ch;
      ++path_ind;
    }
    collector.path[path_ind] = '\0';
    for (u32 f = NORTH; f <= WEST; ++f) {         // send on to neighbors
      if (collector.out_face != f) {
        if (collector.out_face == 1)      in = 2; // swap around south and east
        else if (collector.out_face == 2) in = 1;
        else                              in = collector.out_face;
        if (f == 1)                       out = 2;
        else if (f == 2)                  out = 1;
        else                              out = f;
        switch ((4 + out - in) % 4) {              // find the dir l, r, or f
        case 1: dir = 'l'; break;
        case 2: dir = 'f'; break;
        case 3: dir = 'r'; break;
        default: pprintf(" L hork %d to %d is %d\n", in, out, ((4 + out - in) % 4)); return;
        }
        facePrintf(f, "c%d %s%c\n",
                   count, collector.path, dir);    // append dir and send onward
      }
    }
  }
}

void setup() {
  ident = random(100);                             // my unique identity
  collector.initialized = false;                   // is not yet initialized
  Body.reflex('c', noticeCollector);               // collector notification packets 'c'
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);                    // heartbeat
  collector.report(ident + random(20));            // repot quasi-random number
}


#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_3(c,o,l)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
