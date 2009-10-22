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
  ledToggle(BODY_RGB_BLUE_PIN);                    // blue heartbeat
  report_int(45);                                  // repot an integer
  report_double(3.14159);                          // repot a double
  report_string("schulte");                        // repot a string
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_3(c,o,l)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
