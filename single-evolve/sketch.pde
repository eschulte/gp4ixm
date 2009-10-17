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
#define TOURNAMENT_SIZE 4

/*
 * Reverse Polish Notation Calculator 
 */
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

/*
 * Evaluation
 */
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

/*
 * Individual
 */
struct individual {
  char representation[IND_SIZE];
  int fitness;
  int size() {
    int size = 0;
    while(representation[size] != '\0') ++size;
    return size;
  }
  int score();
};
int individual::score() {
  int values[CHECK_SIZE];
  fitness = 0;
  int difference;
  char goal[4] = "xx*";
  for(int i=0; i<CHECK_SIZE; i++) values[i] = random(10);
  for(int i=0; i<CHECK_SIZE; ++i) {
    difference = (evaluate(values[i], goal) - evaluate(values[i], representation));
    if (difference < 0)
      fitness = fitness - difference;
    else
      fitness = fitness + difference;
  }
  return fitness;
}

/*
 * Population
 */
struct population {
  individual pop[POP_SIZE];
  void       incorporate(individual ind);
  individual tournament();
  individual crossover(individual mother, individual father);
  individual breed();
  individual best() {
    individual best = pop[0];
    for(int i=0; i<POP_SIZE; ++i) if (pop[i].fitness < best.fitness) best = pop[i];
    return best;
  }
  int best_fitness() {
    int best = pop[0].fitness;
    for(int i=0; i<POP_SIZE; ++i) if (pop[i].fitness < best) best = pop[i].fitness;
    return best;
  }
  double mean_fitness() {
    double mean = 0;
    for(int i=0; i<POP_SIZE; ++i) mean = mean + pop[i].fitness;
    return (mean / POP_SIZE);
  }
};
void population::incorporate(individual ind) { // add a new individual, evicting the worst
  int worst_ind = 0;
  for(int i=0; i<POP_SIZE; ++i)
    if (pop[i].fitness > pop[worst_ind].fitness)
      worst_ind = i;
  pop[worst_ind] = ind;
}
individual population::tournament() {          // select individual with tournament of size SIZE
  individual fighters[TOURNAMENT_SIZE];
  for(int i=0; i<TOURNAMENT_SIZE; ++i)
    fighters[i] = pop[random(POP_SIZE)];
  individual winner = fighters[0];
  for(int i=0; i<TOURNAMENT_SIZE; ++i)
    if(fighters[i].fitness < winner.fitness)
      winner = fighters[i];
  return winner;
}
individual population::crossover(individual mother, individual father) {
  individual child;
  int shortest = mother.size();
  if (father.size() < shortest) shortest = father.size();
  int crossover_point = random(shortest);
  for(int i=0; i<crossover_point; i++)
    child.representation[i] = mother.representation[i];
  for(int i=crossover_point; i<shortest; i++)
    child.representation[i] = father.representation[i];
  child.representation[shortest+1] = '\0';
  child.score();
  return child;
}
individual population::breed() {               // breed two members returning a new individual
  return crossover(tournament(), tournament());
}
population pop;

/*
 * Helper Functions
 */
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
  ind.score();                                 // evaluate the fitness of the new individual
  return ind;
}

void setup() {
  for(int i = 0; i < POP_SIZE; ++i)            // randomly generate a population
    pop.pop[i] = new_ind();
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);                // heartbeat
  // add new bred individual
  pop.incorporate(pop.breed());
  // output best score
  pprintf("best fitness is %d\n", pop.best_fitness());
  pprintf("mean fitness is ");
  facePrint(SOUTH, pop.mean_fitness());
  pprintf("\n");
  pprintf("best individual is %d long and is %s\n", pop.best().size(), pop.best().representation);
  // output crossover test 
  int cross_ind = random(POP_SIZE - 2);
  pprintf("first individual: %s\n", pop.pop[cross_ind]);
  pprintf("second individual: %s\n", pop.pop[cross_ind + 2]);
  pprintf("crossover: %s\n", pop.crossover(pop.pop[cross_ind], pop.pop[cross_ind+2]));
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_2(g,p)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
