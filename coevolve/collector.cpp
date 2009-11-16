#include "collector.h"
#include "SFBRandom.h"          // For random(int)
#include "SFBPacket.h"          // For packetSource
#include "SFBReactor.h"         // For Body
#include "SFBPrint.h"           // For facePrint
#include "SFBPrintf.h"          // For pprintf, etc
#include "SFBAlarm.h"           // For Alarms, etc

#define MAX_DIST 100

struct Collector {
  bool initialized;
  int  count;                 // keep track of the last update
  u32  out_face;              // the immediate face through which to send data back
  char path[MAX_DIST];        // the path back to the central scrutinizer
  int ind;                    // counter used by report_prefix/postfix
  // a variety of functions for reporting back to the central scrutinizer
  void report_prefix();
  void report_postfix();
  void report_string(const char * val) {
    if (initialized) {
      report_prefix();
      facePrintf(out_face, "c%s ", val);
      report_postfix();
    }
  }
  void report_double(double val) {
    if (initialized) {
      report_prefix();
      facePrintf(out_face, "c"); facePrint(out_face, val); facePrintf(out_face, " ");
      report_postfix();
    }
  }
  void report_int(int val) {
    if (initialized) {
      report_prefix();
      facePrintf(out_face, "c%d ", val);
      report_postfix();
    }
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

void Collector::report_prefix() {
  ind = 0;
  while(path[ind] != '\0') ++ind;       // rewind to the end of the string
  while(ind > 0) {                      // then step back to front building an R packet
    --ind; facePrintf(out_face, "R%c", reverseStep(path[ind]));
  }
}

void Collector::report_postfix() {
  while(path[ind] != '\0') {            // then step back to the end recording position
    facePrintf(out_face, "%c", path[ind]); ++ind;
  }
  facePrintf(out_face, "\n");           // end the packet
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

void collector_init() {
  Collector collector;
  collector.initialized = false;
  Body.reflex('c', noticeCollector);
}

void report_int(int val) {
  collector.report_int(val);
}

void report_string(const char * val) {
  collector.report_string(val);
}

void report_double(double val) {
  collector.report_double(val);
}
