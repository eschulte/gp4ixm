/*                                             -*- mode:C++ -*-
 *
 * Sketch description: This sketch provides a function for sending
 *   information back to a central scrutinizer at irregular intervals
 *   keeping track of the relative location of the sender.  To begin
 *   collecting data the scrutinizer must send out a request in the
 *   following form
 *
 *   [start|stop] key rate
 *
 *   where
 *   
 *   - [start|stop] indicates whether to start or stop sending the
 *                  indicated information
 *   
 *   - key maps to some option programmed into the sketch as
 *         demonstrated below.
 *
 *   - rate optionally sets the rate in microseconds at which data
 *     will be sent, actuall data will be sent back at intervals of
 *     rate/SPREAD with a chance of 1/SPREAD
 * 
 * Sketch author: Eric Schulte
 *
 */
#include "CDD.h"                // For CDDStart, etc

int SPREAD = 24;                // spread out update messages
int MAX_DIST = 24;              // maximum number of steps from scrutinizer to dest

/* Packet handler on ')'
     instruct board to start/stop sending data updates
   Elements
     - + or -
     - key
     - rate
     - return coordinates
   Examples
     ")k+ 1000 path"
     ")k-"
 */
void dc_request(u8 * packet) {
  u8 op, key;
  if (packetScanf(packet, ")%c%c", &key, &op) != 3) {
    pprintf("L bad '%#p'\n",packet);
    return;
  }
  bool on;
  switch (op) {
  case '+':  on = true; break;
  case '-':  on = false; break;
  default: pprintf("L hork %c\n",op); return;
  }
  // dc_reset(key, on, path);
}

void dc_reset(u32 key, bool enable) {
  // setup key to begin reporting back to the scrutinizer
}

/* Packet handler on '('
     returns data to the scrutinizer
   Elements
     - key
     - value
     - return_path
   Examples
     ")k value return_path"
*/
void dc_response(u8 * packet) {
  u8 key, val;
  if (packetScanf(packet, ")%c %d", &key, &val) < 4) {
    pprintf("L bad '%#p'\n",packet);
  }
}

void setup() {
  Body.reflex(')', dc_request);
  Body.reflex('(', dc_response);
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);
}


#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)      // [Optional: Code number representing you]
#define SFB_SKETCH_PROGRAM_ID B36_2(d,c)        // [Optional: Code number representing this sketch]
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"    // [Optional: Copyright information string]
