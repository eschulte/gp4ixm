/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Run GP on a single ixm board.
 *
 * Sketch author: Eric Schulte
 *
 */
#define POP_SIZE 100
#define IND_SIZE 24
#define BUILDING_BLOCKS "0123456789x+-*/"
#define DEFAULT_VAL 0
#define MUTATION_PROB 4                        // PROB/SIZE = chance_mut of each spot in rep.
#define MUTATION_TICK 10                       // ms per mutation
#define BREEDING_TICK 10                       // ms per breeding
#define INJECTION_TICK 100                     // ms per breeding
#define CHECK_SIZE 10
#define TOURNAMENT_SIZE 4

char goal[100] = "xx*";

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
  void mutate();
  individual copy() {
    individual my_copy;
    for(int i=0; i<IND_SIZE; i++)
      my_copy.representation[i] = representation[i];
    my_copy.fitness = fitness;
    return my_copy;
  };
};
int individual::score() {
  // int values[CHECK_SIZE];
  fitness = 0;
  int difference;
  // for(int i=0; i<CHECK_SIZE; i++) values[i] = random(10);
  for(int i=0; i<CHECK_SIZE; ++i) {
    difference = (evaluate(i, goal) - evaluate(i, representation));
    if (difference < 0)
      fitness = fitness - difference;
    else
      fitness = fitness + difference;
  }
  return fitness;
}
void individual::mutate() {                    // mutate an individual (each place change 1/size)
  char possibilities[16] = BUILDING_BLOCKS;
  for(int i=0; i<size(); ++i)
    if(random(size()) == MUTATION_PROB)
      representation[i] = possibilities[random(15)];
  score();
}

/*
 * Helper Functions
 */
individual new_ind() {                         // randomly generate a new individual
  individual ind;
  int index = 0;
  ind.fitness = -1;
  char possibilities[16] = BUILDING_BLOCKS;
  for(int i = 0; i < random(IND_SIZE); ++i) {
    ind.representation[i] = possibilities[random(15)];
    index = i;
  }
  ind.representation[index+1] = '\0';
  ind.score();                                 // evaluate the fitness of the new individual
  return ind;
}

individual crossover(individual mother, individual father) {
  individual child;
  // int index = 0;
  // int mother_cross = random(mother.size());
  // int father_cross = random(father.size());
  // for(int i=0; i<mother_cross; i++) {
  //   child.representation[index] = mother.representation[index];
  //   ++index;
  // }
  // for(int i=father_cross; i<father.size(); i++) {
  //   if (i >= IND_SIZE) break;                   // protect from overflowing individuals
  //   child.representation[index] = father.representation[i];
  //   ++index;
  // }
  // child.representation[index] = '\0';
  child = father.copy();
  child.score();
  return child;
}

/*
 * Population
 */
struct population {
  individual pop[POP_SIZE];
  void       rescore();
  void       incorporate(individual ind);
  individual tournament();
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
void population::rescore() {                   // re-evaluate the fitness of every individual
  for(int i=0; i<POP_SIZE; ++i)
    pop[i].score();
}
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
individual population::breed() {               // breed two members returning a new individual
  return crossover(tournament(), tournament());
}
population pop;

/*
 * Alarms (Mutation and Breeding) eventually (Sharing and Data collection)
 */
static void do_mutate(u32 when) {
  individual new_guy = pop.tournament().copy();
  new_guy.mutate();
  pop.incorporate(new_guy);
  Alarms.set(Alarms.currentAlarmNumber(), when+MUTATION_TICK);
}
static void do_breed(u32 when) {
  pop.incorporate(pop.breed());
  Alarms.set(Alarms.currentAlarmNumber(), when+BREEDING_TICK);
}
static void do_inject(u32 when) {
  pop.incorporate(new_ind());
  Alarms.set(Alarms.currentAlarmNumber(), when+INJECTION_TICK);
}

/*
 * Goal Updates
 */
int goal_seconds = 0;
void newGoal(u8 * packet) {
  char ch;
  int goal_ind = 0;
  if (packetScanf(packet, "g ") != 2) {
    pprintf("L bad '%#p'\n",packet);
    return;
  }
  while(packetScanf(packet, "%c", &ch)) {      // extract the return path
    goal[goal_ind] = ch;
    ++goal_ind;
  }
  goal_seconds = 0;
  goal[goal_ind] = '\0';
  pop.rescore();
  pprintf("new goal is %s\n", goal);
}

void setup() {
  Body.reflex('g', newGoal);                   // reset the goal function.
  for(int i = 0; i < POP_SIZE; ++i)            // randomly generate a population
    pop.pop[i] = new_ind();
  int alarm_index;
  alarm_index = Alarms.create(do_mutate);      // begin the mutation alarm
  Alarms.set(alarm_index,millis() + 1000);
  alarm_index = Alarms.create(do_breed);       // begin the breeding alarm
  Alarms.set(alarm_index,millis() + 1250);
  alarm_index = Alarms.create(do_inject);      // begin the injection alarm
  Alarms.set(alarm_index,millis() + 2000);
}

void loop() {
  delay(1000); ++goal_seconds;                 // heartbeat
  ledToggle(BODY_RGB_BLUE_PIN);
  pprintf(" \n");                              // print status information
  pprintf("%d second on %s\n", goal_seconds, goal);
  pprintf("best fitness is %d\n", pop.best_fitness());
  pprintf("mean fitness is "); print(pop.mean_fitness()); pprintf("\n");
  pprintf("best individual is %d long and is %s\n", pop.best().size(), pop.best().representation);
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_2(g,p)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
