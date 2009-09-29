/*                                             -*- mode:C++; fill-column:100 -*-
  CDD.h - Connection Direction Detection via GPIO pins
  Copyright (C) 2009 The Regents of the University of New Mexico.  All rights reserved.

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
  USA

  $Id$
*/

/**
  \file CDD.h -  Connection Direction Detection via GPIO pins
  \author David H. Ackley.  
  \date (C) 2009 All rights reserved.
  \lgpl
 */

#ifndef CDD_H
#define CDD_H

#include "SFBTypes.h"           /* For u8 */
#include "SFBConstants.h"       /* For FACE_COUNT */

#include "Grid2D.h"             /* For Point2D */

enum CDDOrientation {
  DONT_KNOW,      // Data pins unconnected or too little data
  UPRIGHT,        // We are upright according to at least two pins
  INVERTED,       // We are inverted according to at least two pins
  NEITHER,        // According to at least one pin we connected in some nonstandard way
  UNSURE,         // Too little data, but might resolve itself later
  NOT_IN_USE      // Not performing CDD on this face
};

const char * CDDGetOrientationName(u32 orient) ; // orient is one of the CDDOrientations

u32 CDDGetOrientation(u32 face) ;
u32 CDDGetConnectedFace(u32 face) ;      // Returns NORTH..WEST or FACE_COUNT if unknown

void CDDStart();
void CDDStop();

void CDDReset(u32 face, bool enable = true) ;

void facePrintCDDInternals(u32 toFace, u32 aboutFace) ;

bool CDDMapIn(u32 face, const Point2D them, Point2D & us) ;

#endif /* CDD_H */
