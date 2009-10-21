/*
  collector.h
  
  send data back to a laptop
  
*/

#ifndef COLLECTOR_H
#define COLLECTOR_H

#include "SFBTypes.h"           /* For u8 */
#include "SFBConstants.h"       /* For FACE_COUNT */

struct Collector {
  bool initialized;
  int  count;                 // keep track of the last update
  u32  out_face;              // the immediate face through which to send data back
  char path[MAX_DIST];        // the path back to the central scrutinizer
  void report(int val);       // reporting string "Rd1Rd2Rd3Rd4cvalue d4d3d2d1\n"
};

void collector_init();

#endif /* collector_H */
