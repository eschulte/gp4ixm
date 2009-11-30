/*
  collector.h
  
  send data back to a laptop
  
*/

#ifndef COLLECTOR_H
#define COLLECTOR_H

#include "SFBTypes.h"           /* For u8 */
#include "SFBConstants.h"       /* For FACE_COUNT */
#include "SFBPrintf.h"          /* For pprintf, etc */

void collector_init();

void report_int(int val);
void report_double(double val);
void report_string(const char * val);
void save_int(int val);
void save_double(double val);
void save_string(const char * val);

#endif /* collector_H */
