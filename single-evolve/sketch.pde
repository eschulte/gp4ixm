/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Run GP on a single ixm board.
 *
 * Sketch author: Eric Schulte
 *
 */
#define POP_SIZE 24
#define IND_SIZE 24
#define DEFAULT_VAL 0
#define CHECK_SIZE 10

struct RpnStack {
  int ind;
  int stack[IND_SIZE];
  int default_value;
  void reset() { ind = 0; default_value = DEFAULT_VAL; }
  void push_value(int val) { stack[ind] = val; ++ind; return; }
  int pop_value() {
    if(ind > 0) {
      --ind; return stack[ind];
    } else
      return default_value;
  }
  int value() { return stack[(ind - 1)]; }
  void apply(char op);
};
void RpnStack::apply(char op) {
  int right = pop_value();
  int left = pop_value();
  int result;
  if     (op == '+')   result = (left + right);
  else if(op == '-')   result = left - right;
  else if(op == '*')   result = left * right;
  else if(op == '/')   if (right == 0) result = 0; else result = (left / right);
  else             {   pprintf("L hork on operator %c\n", op); return; }
  push_value(result);
}
RpnStack rpn_stack;

int evaluate(int x, char * representation) {
  char ch;
  rpn_stack.reset();
  for(int i=0; i<IND_SIZE; ++i) {              // step through the calculation string
    ch = representation[i];
    if (ch == '\0')
      break;
    if(ch >= '0' && ch <= '9')                 // check if we have a number
      rpn_stack.push_value((ch - 48));
    else if (ch == 'x')                        // if x then push x's value
      rpn_stack.push_value(x);
    else                                       // apply operator to rpn_stack
      rpn_stack.apply(ch);
  }
  return rpn_stack.value();
}

struct individual {
  char representation[IND_SIZE];
  double fitness;
  double score();
};
double individual::score () {
  int values[CHECK_SIZE];
  double fitness = 0;
  char goal[4] = "xx*";
  for(int i=0; i<CHECK_SIZE; i++) values[i] = random(10);
  for(int i=0; i<CHECK_SIZE; ++i)
    fitness = fitness + (evaluate(values[i], goal) - evaluate(values[i], representation));
  return fitness;
}

struct population {
  individual pop[POP_SIZE];
  void incorporate(individual ind);
  void evict();
  individual breed();
  individual best() {
    individual best; best.fitness = 0;
    for(int i = 0; i < POP_SIZE; ++i) if (pop[i].fitness < best.fitness) best = pop[i];
    return best;
  }
  double best_fitness() {
    double best = 0;
    for(int i = 0; i < POP_SIZE; ++i) if (pop[i].fitness < best) best = pop[i].fitness;
    return best;
  }
  double mean_fitness() {
    double mean = 0;
    for(int i = 0; i < POP_SIZE; ++i) mean = mean + pop[i].fitness;
    return (mean / POP_SIZE);
  }
};

void population::incorporate(individual ind) { // add a new individual, evicting if necessary
}
void population::evict() {                     // remove an individual from the population
}
individual population::breed() {               // breed two members returning a new individual
  individual child;
  return child;
}

population pop;

individual new_ind() {                         // randomly generate a new individual
  individual ind;
  int index = 0;
  ind.fitness = -1;
  char possibilities[16] = "0123456789x+-*/";
  for(int i = 0; i < random(IND_SIZE); ++i) {
    ind.representation[i] = possibilities[random(15)];
    index = i;
  }
  ind.representation[index+1] = '\0';
  return ind;
}

void setup() {
  for(int i = 0; i < POP_SIZE; ++i)            // randomly generate a population
    pop.pop[i] = new_ind();
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);                // heartbeat
  int index = random(POP_SIZE);
  pprintf("random individual %d is %s\n", index, pop.pop[index].representation);
  pprintf("\twith x = 3 %f\n", evaluate(3, pop.pop[index].representation));
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_2(g,p)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
