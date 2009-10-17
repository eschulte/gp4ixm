/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Evaluates string using a reverse polish
 *                     notation calculator
 *
 * Sketch author: Eric Schulte
 *
 */
#define MAX_VALS 100
#define def_val 0

struct RpnStack {
  int ind;
  int stack[MAX_VALS];
  int default_value;
  void reset() { ind = 0; default_value = def_val; }
  void push_value(int val) { pprintf("L push[%d] %d\n", ind, val); stack[ind] = val; ++ind; return; }
  int pop_value() {
    pprintf("L pop[%d] %d\n", (ind - 1), stack[(ind - 1)]);
    if(ind > 0) {
      --ind; return stack[ind];
    } else {
      return default_value;
    }
  }
  int value() { pprintf("L value[%d] %d\n", (ind - 1), stack[(ind - 1)]); return stack[(ind - 1)]; }
  void apply(char op);
};

void RpnStack::apply(char op) {
  pprintf("L apply %c\n", op);
  int right = pop_value();
  int left = pop_value();
  int result;
  if     (op == '+')   result = (left + right);
  else if(op == '-')   result = left - right;
  else if(op == '*')   result = left * right;
  else if(op == '/')   result = if (right = 0) 0 else left / right;
  else             {   pprintf("L hork on operator %c\n", op); return; }
  push_value(result);
}

RpnStack rpn_stack;

void evaluate(u8 * packet) {
  int ind = 0;
  char ch;
  rpn_stack.reset();
  if (packetScanf(packet, "e ") != 2) {
    pprintf("L bad '%#p'\n",packet);
    return;
  }
  pprintf("L evaluating packet '%#p'\n", packet);
  while(packetScanf(packet, "%c", &ch)) {          // step through the calculation string
    if(ch >= '0' && ch <= '9')                     // check if we have a number
      rpn_stack.push_value((ch - 48));
    else                                           // apply operator to rpn_stack
      rpn_stack.apply(ch);
    ++ind;
  }
  facePrintf(packetSource(packet),
             "a %d\n", rpn_stack.value());         // return the resulting value
}

void setup() {
  Body.reflex('e', evaluate);                      // evaluate packets on 'e'
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_GREEN_PIN);                   // heartbeat
}


#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_4(e,v,a,l)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
