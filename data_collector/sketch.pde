/*                                             -*- mode:C++ -*-
 *
 * Sketch description: This sketch provides a function for sending
 *   information back to a central scrutinizer at irregular intervals.
 *   To begin collecting data the scrutinizer must send out a request
 *   in the following form
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
 *   - rate optionally sets the rate at which data will be sent 
 * 
 * Sketch author: Eric Schulte
 *
 */


// [Helper functions, if needed, go here]


void setup() {
  // [One time setup instructions go here]
}

void loop() {
  // [Repeating main loop instructions go here]
}


#define SFB_SKETCH_CREATOR_ID "Eric Schulte"    // [Optional: Code number representing you]
#define SFB_SKETCH_PROGRAM_ID "Data Collector"  // [Optional: Code number representing this sketch]
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"    // [Optional: Copyright information string]
