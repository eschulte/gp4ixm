#include "Grid2D.h"
#include "SFBPrint.h"           // For facePrintln
#include "SFBPrintf.h"          // For facePrintf
#include "SFBPacket.h"          // For packetCursor, packetReread

Point2D Point2D::operator*(const Mat2D m) const {
  Point2D result;
  for (u32 r = 0; r < 2; ++r)
    for (u32 c = 0; c < 2; ++c)
      result.d[c] += d[r]*m.d[r][c];
  return result;
}

Point2D & Point2D::operator*=(const Mat2D m) {
  *this = (*this)*m;
  return *this;
}

void Point2D::print(u8 face) const {
  facePrintf(face,"(%d,%d)",getX(),getY());
}

void Point2D::println(u8 face) const {
  this->print(face);
  facePrintln(face);
}

bool packetRead(u8 * packet, Point2D & dest) {
  s32 x, y;
  u32 cursor = packetCursor(packet);

  if (packetScanf(packet,"(%d,%d)",&x,&y) != 5 
      || x > S16_MAX || x < S16_MIN 
      || y > S16_MAX || y < S16_MIN) {
    packetReread(packet,cursor);
    return false;
  }
  dest.setX((s16) x);
  dest.setY((s16) y);
  return true;
}

static const Mat2D flipAxes[FACE_COUNT/2] = {
  Mat2D(-1, 0, 0, 1),       // Flip around NORTH or SOUTH
  Mat2D( 1, 0, 0,-1)        // Flip around EAST or WEST
};
static const Mat2D rotations[360/90] = {
  Mat2D( 1, 0, 0, 1),          // Rotate 0 degrees CCW
  Mat2D( 0, 1,-1, 0),          // Rotate 90 degrees CCW
  Mat2D(-1, 0, 0,-1),          // Rotate 180 degrees CCW
  Mat2D( 0,-1, 1, 0)           // Rotate 270 degrees CCW
};
static const Point2D faceOffsets[FACE_COUNT] = {
  Point2D( 0, 1),               // Things N of us are +1 in y
  Point2D( 0,-1),               // Things S of us are -1 in y
  Point2D( 1, 0),               // Things E of us are +1 in x
  Point2D(-1, 0)                // Things W of us are -1 in x
};

// How many CCW turns to rotate this face to N?
#define CCW_FACE_TO_N(face) GET_MAP4BY2(MAP4BY2(0,2,1,3),(face)) 

// How many CCW turns to rotate N to this face?
#define CCW_N_TO_FACE(face) GET_MAP4BY2(MAP4BY2(0,2,3,1),(face)) 

Point2D Point2D::mapIn(u8 ourFace, u8 theirFace, bool theyreInverted) const {
  API_ASSERT_VALID_FACE(ourFace);
  API_ASSERT_VALID_FACE(theirFace);

  Point2D result = *this;

  // Remap if needed so that they are upright wrt us.
  if (theyreInverted)
    result *= flipAxes[theirFace>>1];
  
  // Figure out the net rotation amount to bring our N's into alignment
  u32 rotIdx = (2+CCW_N_TO_FACE(ourFace)+CCW_FACE_TO_N(theirFace))%FACE_COUNT;

  // Rotate point into our alignment
  result *= rotations[rotIdx];

  // Finally, offset it by one in the direction of our connected face
  result += faceOffsets[ourFace];

  return result;                // There.  That's what they were trying to say..
}

