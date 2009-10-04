/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Evaluates string using a reverse polish
 *                     notation calculator
 *
 * Sketch author: Eric Schulte
 *
 */
#define MAX_VALS 100
int default_value;

struct RpnStack {
  int ind;
  int stack[MAX_VALS];
  int default_value;
  void push_value(int val) { stack[ind] = val; ++ind; return; }
  int pop_value() {
    if(ind > 0) {
      --ind; return stack[(ind + 1)];
    } else {
      return default_value;
    }
  }
  int value() {return stack[ind]; }
  void apply(char op);
};

void RpnStack::apply(char op) {
  int right = pop_value();
  int left = pop_value();
  int result;
  switch(op) {
  case '+': result = left + right;
  case '-': result = left - right;
  case '*': result = left * right;
  case '/': result = left / right;
  default: pprintf("L hork on operator %c\n", op); return;
  }
  push_value(result);
}

void evaluate(u8 * packet) {
  int ind = 0;
  char ch;
  int new_val = -1;
  RpnStack rpn_stack;
  rpn_stack.default_value = default_value;
  if (packetScanf(packet, "e ") != 2) {
    pprintf("L bad '%#p'\n",packet);
    return;
  }
  while((packetScanf(packet, "%d", &new_val)) ||   // step through the calculation string
        (packetScanf(packet, "%c", &ch))) {
    if(new_val >= 0)                               // add integer to rpn_stack
      rpn_stack.push_value(new_val);
    else                                           // apply operator to rpn_stack
      rpn_stack.apply(ch);
    new_val = -1;
    ++ind;
  }
  facePrintf(packetSource(packet),
             "a %d\n", rpn_stack.value());         // return the resulting value
}

void setup() {
  default_value = 0;
  Body.reflex('e', evaluate);                      // evaluate packets on 'e'
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_GREEN_PIN);                   // heartbeat
}


#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_4(e,v,a,l)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
