/* sketch-wrapper.cpp
 *
 * Do includes and such necessary to support
 * an Arduinoish sketch code, which we include from here
 */

#include "sfb.h"

void setup();

void loop(); 

#include "sketch.pde"

/* Finally, pull in a fresh header block -- at the bottom, so
 * sketch.pde can define SFB_SKETCH_CREATOR_ID and
 * SFB_SKETCH_PROGRAM_ID (and SFB_SKETCH_COPYRIGHT_NOTICE) if/as it
 * wants.
 */ 

#include "SFBProvenanceData.h" 

