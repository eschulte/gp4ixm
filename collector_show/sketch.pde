/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Mechanisms for collecting data from a group of
 *   IXM boards are irregular intervals
 *
 * Sketch author: Eric Schulte
 *
 */
#include "collector.h"

int val;

void pushUp(u8 * packet) {
  if (packetScanf(packet, "u") != 1)
    val = val + 5;
}

void setup() {
  val = random(10);
  Body.reflex('u', pushUp);
  collector_init();
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);                    // blue heartbeat
  report_int(val);                                 // repot an value
  if (buttonDown()) {
    val = val + 10;
    pprintf("u\n");
  }
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_5(d,e,m,o,c)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
