/*                                             -*- mode:C++; fill-column:100 -*-
  Grid2D.h - Cheap 2D coordinates usable for SFB grid locations
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
  \file Grid2D.h -  2D coordinates usable for SFB grid locations
  \author David H. Ackley.  
  \date (C) 2009 All rights reserved.
  \lgpl
 */

#ifndef GRID2D_H
#define GRID2D_H

#include "SFBTypes.h"     /* For u8 */
#include "SFBConstants.h" /* For FACE_COUNT */

struct Mat2D {
  Mat2D(s8 d00,s8 d01,s8 d10,s8 d11) {
    d[0][0] = d00;
    d[0][1] = d01;
    d[1][0] = d10;
    d[1][1] = d11;
  }

  s8 d[2][2];
};

struct Point2D {

  s16 d[2];

  Point2D(s16 x = 0, s16 y = 0) { 
    d[0] = x;
    d[1] = y; 
  }
  s16 getX() const { return d[0]; }
  s16 getY() const { return d[1]; }

  void setX(s16 nx) { d[0] = nx; }
  void setY(s16 ny) { d[1] = ny; }

  Point2D(const Point2D & other) {
    d[0] = other.d[0];
    d[1] = other.d[1];
  }
  Point2D operator-(const Point2D arg) const {
    Point2D res = *this;
    res.d[0] -= arg.d[0];
    res.d[1] -= arg.d[1];
    return res;
  }
  Point2D operator+(const Point2D arg) const {
    Point2D res = *this;
    res.d[0] += arg.d[0];
    res.d[1] += arg.d[1];
    return res;
  }
  Point2D & operator-=(const Point2D arg) {
    d[0] -= arg.d[0];
    d[1] -= arg.d[1];
    return *this;
  }
  Point2D & operator+=(const Point2D arg) {
    d[0] += arg.d[0];
    d[1] += arg.d[1];
    return *this;
  }
  Point2D & operator=(const Point2D arg) {
    d[0] = arg.d[0];
    d[1] = arg.d[1];
    return *this;
  }

  void print(u8 face = ALL_FACES) const;

  void println(u8 face = ALL_FACES) const;

  Point2D mapIn(u8 ourFace, u8 theirFace, bool theyreInverted) const ;

  Point2D operator*(const Mat2D m) const ;

  Point2D & operator*=(const Mat2D m) ;

};

inline void facePrint(u8 face, const Point2D pt) {
  pt.print(face);
}
inline void facePrintln(u8 face, const Point2D pt) {
  pt.println(face);
}
bool packetRead(u8 * packet, Point2D & dest) ;

#endif /* GRID2D_H */
