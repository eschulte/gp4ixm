/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Run GP on a single ixm board.
 *
 * Sketch author: Eric Schulte
 *
 */
#include "collector.h"

#define POP_SIZE 100
#define IND_SIZE 24
#define BUILDING_BLOCKS "0123456789x+-*/"
#define DEFAULT_VAL 0
#define CHECK_SIZE 10
#define MAX_GOAL_SIZE 64

char goal[MAX_GOAL_SIZE];
int mutation_tick   = 100;                     // ms per mutation
int breeding_tick   = 100;                     // ms per breeding
int injection_tick  = 100;                     // ms per breeding
int sharing_tick    = 500;                     // ms per sharing
int tournament_size = 4;
int mutation_prob   = 4;                       // PROB/SIZE = chance_mut of each spot

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
    else if (ch == '+' || ch == '-' || ch == '*' || ch == '/')
      rpn_stack.apply(ch);                     // apply operator to rpn_stack
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
    if(random(size()) == mutation_prob)
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
  int mother_cross = random(mother.size());
  int father_cross = random(father.size());
  int index = 0;
  for(int i=0; i<mother_cross; ++i) {
    if (mother.representation[i] == '\0') break;
    child.representation[index] = mother.representation[i];
    ++index;
  }
  for(int i=father_cross; i<father.size(); ++i) {
    if ((i >= (IND_SIZE - 1)) || (father.representation[i] == '\0')) break;
    child.representation[index] = father.representation[i];
    ++index;
  }
  child.representation[index] = '\0';
  child.score();
  return child;
}

void share(individual candidate) {
  pprintf("i ");
  for(int i=0; i<candidate.size(); ++i)
    pprintf("%c", candidate.representation[i]);
  pprintf("\n");
}

/*
 * Population
 */
struct population {
  individual pop[POP_SIZE];
  void       rescore();
  void       reset() {
    for(int i = 0; i < POP_SIZE; ++i)
      pop[i] = new_ind();
  }
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
  individual fighters[POP_SIZE];
  for(int i=0; i<tournament_size; ++i)
    fighters[i] = pop[random(POP_SIZE)];
  individual winner = fighters[0];
  for(int i=0; i<tournament_size; ++i)
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
  if(mutation_tick > 0) {                      // don't reschedule if tick is 0
    if (when+mutation_tick < millis()){
      pprintf("L mutating too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    } else
      Alarms.set(Alarms.currentAlarmNumber(), when+mutation_tick);
  }
}
static void do_breed(u32 when) {
  pop.incorporate(pop.breed());
  if(breeding_tick > 0) {                      // don't reschedule if tick is 0
    if (when+breeding_tick < millis()) {
      pprintf("L breeding too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    } else
      Alarms.set(Alarms.currentAlarmNumber(), when+breeding_tick);
  }
}
static void do_inject(u32 when) {
  pop.incorporate(new_ind());
  if(mutation_tick > 0) {                      // don't reschedule if tick is 0
    if (when+injection_tick < millis()) {
      pprintf("L injecting too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    }
    else
      Alarms.set(Alarms.currentAlarmNumber(), when+injection_tick);
  }
}
static void do_share(u32 when) {
  share(pop.tournament());
  if(mutation_tick > 0) {                      // don't reschedule if tick is 0
    if (when+injection_tick < millis()) {
      pprintf("L sharing too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    }
    else
      Alarms.set(Alarms.currentAlarmNumber(), when+sharing_tick);
  }
}

/*
 * Reflexes
 */
int goal_seconds = 0;
void newGoal(u8 * packet) {
  bool new_p = false;
  char ch;
  int goal_ind = 0;
  if (packetScanf(packet, "g ") != 2) {
    pprintf("L bad goal: '%#p'\n",packet);
    return;
  }
  while((packetScanf(packet, "%c", &ch)) && (goal_ind < MAX_GOAL_SIZE)) {
    if(goal[goal_ind] != ch)
      new_p = true;
    goal[goal_ind] = ch;
    ++goal_ind;
  }
  goal[goal_ind] = '\0';
  if (new_p) {                                    // check if the new goal is new
    ledToggle(BODY_RGB_RED_PIN);
    goal_seconds = 0;
    pop.rescore();
    delay(250);
    pprintf("g %s\n", goal);
    pprintf("L new goal is %s\n", goal);
    ledToggle(BODY_RGB_RED_PIN);
  } else {                                        // indicate seen this before
    ledToggle(BODY_RGB_GREEN_PIN);
    delay(250);
    ledToggle(BODY_RGB_GREEN_PIN);
  }
}

void acceptIndividual(u8 * packet) {
  individual ind;
  int index = 0;
  ind.fitness = -1;
  char ch;
  if (packetScanf(packet, "i ") != 2) {
    pprintf("L bad individual: '%#p'\n",packet);
    return;
  }
  while((packetScanf(packet, "%c", &ch)) && index < IND_SIZE) {
    ind.representation[index] = ch;
    ++index;
  }
  ind.representation[index] = '\0';
  ind.score();
  if(ind.fitness < pop.best_fitness()) {
      ledToggle(BODY_RGB_BLUE_PIN);
      delay(250);
      ledToggle(BODY_RGB_BLUE_PIN);
  }
  pop.incorporate(ind);
}

void reset() {
  pop.reset();                                 // randomly generate a population
  int alarm_index;
  if(mutation_tick > 0) {
    alarm_index = Alarms.create(do_mutate);    // begin the mutation alarm
    Alarms.set(alarm_index,millis() + 1000);
  }
  if(breeding_tick > 0) {
    alarm_index = Alarms.create(do_breed);     // begin the breeding alarm
    Alarms.set(alarm_index,millis() + 1250);
  }
  if(injection_tick > 0) {
    alarm_index = Alarms.create(do_inject);    // begin the injection alarm
    Alarms.set(alarm_index,millis() + 1500);
  }
  if(sharing_tick) {
    alarm_index = Alarms.create(do_share);     // begin the share alarm
    Alarms.set(alarm_index,millis() + 1750);
  }
}

void populationReset(u8 * packet) {
  if (packetScanf(packet, "r") != 1) {
    pprintf("L bad reset: '%#p'\n",packet);
    return;
  }
  char key = '\0';
  int val = 0;
  while (packetScanf(packet, "%c:%d", key, val)) {
    switch(key) {
    case 'm': mutation_tick = val;
    case 'b': breeding_tick = val;
    case 'i': injection_tick = val;
    case 's': sharing_tick = val;
    case 't': tournament_size = val;
    case 'p': mutation_prob = val;
    default: pprintf("L hork on key: %c\n", key);
    }
  }
  reset();
}

void setup() {
  goal[0] = 'x';
  goal[1] = 'x';
  goal[2] = '*';
  goal[3] = '\0';
  collector_init();                            // initialize the collector
  Body.reflex('g', newGoal);                   // reset the goal function.
  Body.reflex('i', acceptIndividual);          // incorporate a neighbor's individual
  Body.reflex('r', populationReset);           // reset the population (and settings)
  reset();
}

void loop() {
  delay(1000); ++goal_seconds;
  pprintf("L \n");                             // print status information
  pprintf("L %d second on %s\n", goal_seconds, goal);
  pprintf("L best fitness is %d\n", pop.best_fitness());
  pprintf("L mean fitness is "); print(pop.mean_fitness()); pprintf("\n");
  pprintf("L best individual is %d long and is %s\n",
          pop.best().size(), pop.best().representation);
  report_double(pop.mean_fitness());
  if (buttonDown()) pop.reset();
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_2(g,p)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
