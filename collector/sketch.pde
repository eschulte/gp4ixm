/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Mechanisms for collecting data from a group of
 *   IXM boards are irregular intervals
 *
 * Sketch author: Eric Schulte
 *
 */
#include "collector.h"

int ident;

void setup() {
  collector_init();
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);                    // heartbeat
  report(45);                                      // repot quasi-random number
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_3(c,o,l)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
