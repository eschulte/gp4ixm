/*
  collector.h
  
  send data back to a laptop
  
*/

#ifndef COLLECTOR_H
#define COLLECTOR_H

#include "SFBTypes.h"           /* For u8 */
#include "SFBConstants.h"       /* For FACE_COUNT */

void collector_init();

void report(int val);

#endif /* collector_H */
