#include "CDD.h"
#include "SFBRandom.h"          // For random(int)
#include "SFBAssert.h"          // For API_BUG, etc
#include "SFBWiring.h"          // For digitalRead, etc
#include "SFBPrintf.h"          // For pprintf, etc
#include "SFBAlarm.h"           // For Alarms, etc

#define FACE_GPIO_COUNT 4

#define TICK_SIZE 2          // ms per tick

#define LISTEN_START 0       // pinMode INPUT pullup high listen
#define SYNC_TARGET 7        // target for hearing other side's sync
#define GOOD_SYNC_WIDTH 2    // +- ticks around SYNC_TARGET to call sync good
#define SEND_START 43        // pinMode OUTPUT write HIGH
#define SEND_SYNC 44         // write Dx = LOW for all x
#define WIDTH_INCR 3         // write Dx = HIGH at SEND_SYNC+(x+1)*WIDTH_INCR
#define FACE_START 58        // when to start the face code
#define FACE_PULSE_WIDTH 2   // size of face pulse width
#define NOMINAL_PERIOD_END 75

#define UNKNOWN_LEVEL 2         // Along with LOW==0, HIGH==1

#define MAX_CONFIDENCE 32
#define CONFIDENT_LEVEL (MAX_CONFIDENCE/4-1)
#define VERY_CONFIDENT_LEVEL (3*MAX_CONFIDENCE/4)

const char * CDDGetOrientationName(u32 orient) {
  switch (orient) {
  case DONT_KNOW: return "Unconnected or unconfident";
  case UPRIGHT: return "Connected upright";
  case INVERTED: return "Connected inverted";
  case NEITHER: return "Nonstandard connection";
  case UNSURE: return "Insufficient or conflicting data";
  case NOT_IN_USE: return "Not detecting connections";
  default: API_BUG(E_API_ARGUMENT);
  }
}
struct PinStat {
  u8 edges;      // how many transitions I saw this listen
  u8 level;      // last level sampled
  u8 low;        // startMs+low is when I saw this go low
  u8 high;       // startMs+high is when I saw this go back high
  u8 faceLow;    // tick of second low on this wire
  u8 faceHigh;   // tick of second high on this wire
  u8 mapVotes[FACE_GPIO_COUNT]; // Votes for what pin this pin is connected to

  void initPeriod() {
    low = 0;
    high = 0;
    faceLow = 0;
    faceHigh = 0;
    edges = 0;
    level = UNKNOWN_LEVEL;
  }
  void reset() {
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) 
      mapVotes[g] = 0;
    initPeriod();
  }

  void listen(u32 sfbPin, u32 onStep) {
    u32 curLevel = digitalRead(sfbPin);

    bool wasKnown = level != UNKNOWN_LEVEL;
    if (curLevel == level/* ||                         // If no change, or
                            (wasKnown && curLevel == LOW)*/) // just starting and not high
      return;                                        // then punt

    level = curLevel;

    if (wasKnown)
      ++edges;
    if (low == 0) {           if (level==LOW)  low = onStep; }
    else if (high == 0) {     if (level==HIGH) high = onStep; }
    else if (faceLow == 0) {  if (level==LOW)  faceLow = onStep; }
    else if (faceHigh == 0) { if (level==HIGH) faceHigh = onStep; }
  }

  u32 pinMapsTo() {
    u32 score = CONFIDENT_LEVEL-1; // Must beat CONFIDENT_LEVEL-1 to count
    u32 destPin = FACE_GPIO_COUNT; // No such pin
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      if (mapVotes[g] > score) {
        destPin = g;
        score = mapVotes[g];
      }
    }
    return destPin;
  }

  void vote() {
    u32 width = -1;             // If wrong edge count, say huge width

    if (edges == 2 || edges == 4) {      // If single (or double, for face eval) good pulse
      width = (high-low)-(WIDTH_INCR-1); //  compute pulse width 
    }

    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      if (mapVotes[g])
        mapVotes[g]--;

      if (width < WIDTH_INCR && mapVotes[g] < MAX_CONFIDENCE)
        mapVotes[g] += 2;
      width -= WIDTH_INCR;
    }
  }

};

struct FaceStat {
  PinStat pinStats[FACE_GPIO_COUNT];
  const u8 face;
  u8 onStep;         // If < periodEnd, what step of this period we're on
  u8 periodEnd;      // ticks in the current period
  u8 confidence;
  u8 judgment;
  u8 faceJudgment;
  u8 faceEstimate;
  u8 faceConfidence;
  u8 syncPos;

  FaceStat(u8 face) : face(face) {
    reset(false);
  }

  void reset(bool active) {
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g)
      pinStats[g].reset();
    judgment = active?DONT_KNOW:NOT_IN_USE;
    onStep = LISTEN_START;      // Ensure next step starts a new period

    faceJudgment = FACE_COUNT;  // No face judgment
    faceConfidence = 0;         // and no confidence
  }

  void endPeriod() {
    onStep = LISTEN_START;
    periodEnd = NOMINAL_PERIOD_END;
  }

  u32 makeJudgment() {
    if (confidence < CONFIDENT_LEVEL) 
      return DONT_KNOW;
    
    u8 uprightVotes = 0;
    u8 invertedVotes = 0;
    u8 otherVotes = 0;
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      u8 destPin = pinStats[g].pinMapsTo();
      if (destPin >= FACE_GPIO_COUNT) // Connects to nothing
        continue;
      if (g == (destPin^1))
        ++uprightVotes;
      else if (g == (3u-destPin))
        ++invertedVotes;
      else
        ++otherVotes;
    }

    if (uprightVotes > 1 && invertedVotes == 0 && otherVotes == 0)
      return UPRIGHT;

    if (uprightVotes == 0 && invertedVotes > 1 && otherVotes == 0)
      return INVERTED;

    if (otherVotes > 0)
      return NEITHER;

    return UNSURE;
  }

  bool goodSync() {
    return syncPos <= SYNC_TARGET+GOOD_SYNC_WIDTH && syncPos >= SYNC_TARGET-GOOD_SYNC_WIDTH;
  }

  void endListening() {
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      pinStats[g].vote();
    }

    syncPos = syncPosition();
    bool disturbed = false;
    if (syncPos == 0) {         // If no opinion on sync position
      confidence /= 2;          // Lose a ton of confidence
      if (confidence == 0)      // If no confidence,
        periodEnd += random(-2,2); // let phase drift
    } else {
      if (syncPos < SYNC_TARGET-1) { // If sync too early, tend to shorten this
        if (random(2)) --periodEnd; // period so next will start sooner
        disturbed = true;          // And it bugs us a little
      } else if (syncPos > SYNC_TARGET+1) { // If sync too late, tend to extend this
        if (random(2)) ++periodEnd; // period so next will start later
        disturbed = true;          // And that bugs us a little
      }  else if (confidence < MAX_CONFIDENCE) { // Else we hit our window; nice
        ++confidence;                       // so gain confidence
      }
      if (disturbed && confidence) // If something was a bit off
        --confidence;              // lose a litle confidence, if had any
    }

    faceJudgment = faceEvaluation();

    judgment = makeJudgment();
  }
  void startListening() {
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      u32 sfbPin = pinInFace(g,face);
      pinMode(sfbPin, INPUT);
      digitalWrite(sfbPin, HIGH); // set pullup on input pin
      pinStats[g].initPeriod();
    }
  }
  void startSending() {
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      u32 sfbPin = pinInFace(g,face);
      pinMode(sfbPin, OUTPUT);
      digitalWrite(sfbPin, HIGH);
    }
  }
  void send() {
    u32 sendPhase = onStep-SEND_START;
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      u32 sfbPin = pinInFace(g,face);
      bool showLow = sendPhase>0 && sendPhase < (4+g*WIDTH_INCR);
      digitalWrite(sfbPin,showLow?LOW:HIGH);
    }
  }
  void sendFace() {
    u32 faceStep = onStep-FACE_START;
    bool sendIt = confidence > VERY_CONFIDENT_LEVEL;

    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      u32 sfbPin = pinInFace(g,face);
      u32 startOffset = g+1;    // Start position depends only on pin
      u32 faceWidth = FACE_PULSE_WIDTH*(face+1); // Width depends only on face
      bool showLow = sendIt && faceStep>=startOffset && faceStep < startOffset+faceWidth;
      digitalWrite(sfbPin,showLow?LOW:HIGH);
    }
  }
  u32 faceEvaluation() {

    if (!goodSync()) {           
      faceConfidence /= 2;
      return (faceConfidence > CONFIDENT_LEVEL)?faceEstimate:FACE_COUNT;
    }

    for (u32 p = 0; p < FACE_GPIO_COUNT; ++p) {

      if (pinStats[p].faceLow && pinStats[p].faceHigh) {
        u32 g = pinStats[p].pinMapsTo();

        if (g == FACE_GPIO_COUNT)
          continue;

        u32 tface = (pinStats[p].faceHigh-pinStats[p].faceLow)/FACE_PULSE_WIDTH-1;

#if 0
        if (log)
          pprintf(" [p%d fl=%d fh=%d sp%d g%d FS-SS%d tface%d]",
                  p,pinStats[p].faceLow,pinStats[p].faceHigh,syncPos,
                  g,(FACE_START-SEND_SYNC),
                  tface);
#endif

        if (faceConfidence == 0) {
          faceEstimate = tface;
          faceConfidence = 1;
        } else if (faceEstimate == tface) {
          if (faceConfidence < MAX_CONFIDENCE)
            ++faceConfidence;
        } else {
          if (faceConfidence < 3) 
            faceConfidence = 0;
          else faceConfidence -= 3;
        }
      }
    }
#if 0
    if (log) {
      facePrintf(ALL_FACES,"\n");
      //      if (winningFace == FACE_COUNT) 
      //        pprintf(" --\n");
      //      else
      //        pprintf(" >>%c\n",FACE_CODE(winningFace));
    }
#endif

    return (faceConfidence > CONFIDENT_LEVEL)?faceEstimate:FACE_COUNT;
  }

  u32 syncPosition() {
    u8 countSyncs[FACE_GPIO_COUNT];

    // Horrible quadratic match counts
    for (u32 g1 = 0; g1 < FACE_GPIO_COUNT; ++g1) {
      countSyncs[g1] = 0;
      if (pinStats[g1].low == 0)
        continue;
      for (u32 g2 = 0; g2 < FACE_GPIO_COUNT; ++g2) {
        if (g1==g2 || pinStats[g2].low == 0)
          continue;
        if (pinStats[g1].low <= pinStats[g2].low+1 &&
            pinStats[g2].low <= pinStats[g1].low+1) {
          ++countSyncs[g1];
        }
      }
    }

    u32 count = 0;
    u32 position = 0;
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) {
      if (countSyncs[g] > count) {
        count = countSyncs[g];
        position = g;
      }
    }
    return pinStats[position].low; // 0 -> no consensus, else ticks-past-period start of most-matching-pin
  }

  void listen() {
    for (u32 g = 0; g < FACE_GPIO_COUNT; ++g) 
      pinStats[g].listen(pinInFace(g,face),onStep);
  }

  void step() {
    if (judgment == NOT_IN_USE)
      return;

    if (onStep > periodEnd)     // Hit period end?
      endPeriod();              // Do end-of-period steps

    if (onStep==LISTEN_START)   // Start new period?
      startListening();         // Yes

     if (onStep < SEND_START)   // In listening period?
       listen();                // Then listen
     else if (onStep == SEND_START) {
       endListening();
       startSending();
     } else if (onStep < FACE_START) {
       send();                  // So send
     } else {                   // >= FACE_START
       sendFace();
     }

     ++onStep;                  // End of step
  }

  bool mapIn(Point2D them, Point2D & us) {
    if (faceJudgment == FACE_COUNT) // Can't know yet/currently
      return false;

    bool isInverted;
    if (judgment==UPRIGHT) isInverted = false;
    else if (judgment==INVERTED) isInverted = true;
    else return false;          // Can't do it..

    us = them.mapIn(face,faceJudgment,isInverted);
    return true;  
  }

};

FaceStat faceStats[FACE_COUNT] = {
  FaceStat(NORTH), FaceStat(SOUTH), FaceStat(EAST), FaceStat(WEST)
};

bool CDDMapIn(u32 face,const Point2D them, Point2D & us) {
  API_ASSERT_VALID_FACE(face);
  return faceStats[face].mapIn(them,us);
}

u32 CDDGetOrientation(u32 face) {
  API_ASSERT_VALID_FACE(face);
  return faceStats[face].judgment;
}

u32 CDDGetConnectedFace(u32 face) {
  API_ASSERT_VALID_FACE(face);
  return faceStats[face].faceJudgment;
}

void CDDReset(u32 face, bool enable) {
  API_ASSERT_MAX(face,FACE_COUNT);
  faceStats[face].reset(enable);
}

static void mstimer(u32 when) {
  for (u32 f = NORTH; f <= WEST; ++f)
    faceStats[f].step();
  Alarms.set(Alarms.currentAlarmNumber(), when+TICK_SIZE);
}

void facePrintCDDInternals(u32 toFace, u32 aboutFace) {
  API_ASSERT_VALID_EXTENDED_FACE(toFace);
  API_ASSERT_VALID_FACE(aboutFace);

  FaceStat & f = faceStats[aboutFace];
  facePrintf(toFace,
             "[c=%d,j=%d,s=%d]Face:%c (%s)",
              f.confidence,
              f.judgment,
              f.syncPos,
              (f.faceJudgment==FACE_COUNT)?'-':FACE_CODE(f.faceJudgment),
              CDDGetOrientationName(f.judgment));
}

static u32 cddAlarmIndex = 0;

void CDDStart() {
  API_ASSERT_ZERO(FACE_D0_PIN); // This code relies on FACE_D0_PIN..FACE_D3_PIN being 0..3!

  if (cddAlarmIndex == 0)
    cddAlarmIndex = Alarms.create(mstimer);

  for (u32 f = NORTH; f <= WEST; ++f) { // Enable CDD on all faces that..
    bool takeIt = true;
    for (u32 p = FACE_D0_PIN; p <= FACE_D3_PIN; ++p) {
      u32 sfbPin = pinInFace(p,f);
      if (GET_SKETCH_FLAG(sfbPin)) {   // ..have NO data pins under sketch control
        takeIt = false;
        break;
      }
    }
    CDDReset(f,takeIt);
  }

  Alarms.set(cddAlarmIndex,millis());
}

void CDDStop() {
  if (cddAlarmIndex)
    Alarms.cancel(cddAlarmIndex);
}

