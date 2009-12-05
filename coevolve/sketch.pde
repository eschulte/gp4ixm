/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Run GP on a single ixm board with coevolution
 *
 * Sketch author: Eric Schulte
 *
 * new 2
 *
 */
#include "collector.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define COEVOLVE // uncomment this to enable coevolution
#define POP_SIZE 100
#define EVAL_POP_SIZE 20
#define IND_SIZE 24
#define BUILDING_BLOCKS "0123456789x+-*/"
#define DEFAULT_VAL 0
#define CHECK_SIZE 5
#define MAX_GOAL_SIZE 64
#define CHECK_RANGE 100

char goal[MAX_GOAL_SIZE];

// GP parameters for evolution of individual functions
int mutation_tick   = 100;                     // ms per mutation
int breeding_tick   = 100;                     // ms per breeding
int injection_tick  = 100;                     // ms per breeding
int sharing_tick    = 500;                     // ms per sharing
int tournament_size = 4;                       // number of individuals selected per tournament
int mutation_prob   = 4;                       // PROB/SIZE = chance_mut of each spot

#ifdef COEVOLVE
// GA parameters for evolution of eval-arrays
int eval_mutation_tick   = 5000;               // ms per mutation
int eval_breeding_tick   = 5000;               // ms per breeding
int eval_injection_tick  = 5000;               // ms per breeding
int eval_sharing_tick    = 10000;              // ms per sharing
int eval_tournament_size = 4;                  // number of individuals selected per tournament
int eval_mutation_prob   = 1;                  // PROB/SIZE = chance_mut of each spot
#endif

// alarm variables
int mutation_alarm_index  = -1;
int breeding_alarm_index  = -1;
int injection_alarm_index = -1;
int sharing_alarm_index   = -1;
int eval_mutation_alarm_index  = -1;
int eval_breeding_alarm_index  = -1;
int eval_injection_alarm_index = -1;
int eval_sharing_alarm_index   = -1;

#ifdef COEVOLVE
struct eval_individual {
  int representation[CHECK_SIZE];
  double fitness;
  double score();
  double update_fitness(int new_fit) {
    if (fitness == 0)
      fitness = (double) new_fit;
    else
      fitness = ((fitness + (double) new_fit) / 2);
    return fitness;
  }
  void mutate() {
    int old;
    for(int i=0; i<CHECK_SIZE; ++i) {
      old = representation[i];
      if((random(1000)/1000) <= (mutation_prob/CHECK_SIZE)) {
        if (random(2) == 1)
          representation[i] = representation[i] + 1;
        else
          representation[i] = representation[i] - 1;
      }
      if ((representation[i] > CHECK_RANGE) || (representation[i] < -CHECK_RANGE))
        representation[i] = random(-CHECK_RANGE, CHECK_RANGE);
    }
  }
  eval_individual copy() {
    eval_individual my_copy;
    for(int i=0; i<CHECK_SIZE; i++)
      my_copy.representation[i] = representation[i];
    my_copy.fitness = fitness;
    return my_copy;
  };
};
#endif

/*
 * Reverse Polish Notation Calculator
 */
struct RpnStack {
  int ind;
  double stack[IND_SIZE];
  double default_value;
  void reset() { ind = 0; default_value = DEFAULT_VAL; }
  void push_value(int val) { stack[ind] = val; ++ind; return; }
  double pop_value() {
    if(ind > 0) {
      --ind; return stack[ind];
    } else
      return default_value;
  }
  double value() { return stack[(ind - 1)]; }
  void apply(char op);
};
void RpnStack::apply(char op) {
  double right = pop_value();
  double left = pop_value();
  double result;
  if     (op == '+')   result = (left + right);
  else if(op == '-')   result = left - right;
  else if(op == '*')   result = left * right;
  else if(op == '/')   if (right == 0) result = 0; else result = (left / right);
  else if(op == 's')   { push_value(left); result = sin(right); }
  else             {   pprintf("L hork on operator %c\n", op); return; }
  push_value(result);
}
RpnStack rpn_stack;

/*
 * Evaluation
 */
double evaluate(int x, char * representation) {
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
  double fitness;
  int size() {
    int size = 0;
    while(representation[size] != '\0') ++size;
    return size;
  }
  double score();
  double update_fitness(int new_fit) {
    if (fitness == 0)
      fitness = (double) new_fit;
    else
      fitness = ((fitness + (double) new_fit) / 2);
    return fitness;
  }
  void mutate();
  individual copy() {
    individual my_copy;
    for(int i=0; i<IND_SIZE; i++)
      my_copy.representation[i] = representation[i];
    my_copy.fitness = fitness;
    return my_copy;
  };
  bool check() {
    bool ok = true;
    char val;
    for(int i=0; i<size(); i++) {
      val = representation[i];
      if(not (val == '0' || val == '1' || val == '2' || val == '3' || val == '4' ||
              val == '5' || val == '6' || val == '7' || val == '8' || val == '9' ||
              val == '-' || val == '+' || val == '/' || val == '*' || val == 'x')) {
        ok = false;
        pprintf("L bad value %c at [%d]\n", val, i);
      }
    }
    if(size() > IND_SIZE) {
      ok = false;
      pprintf("L bad size %d\n", size());
    }
    return ok;
  }
};
void individual::mutate() {                    // mutate an individual
  char possibilities[16] = BUILDING_BLOCKS;
  for(int i=0; i<size(); ++i)
    if((random(1000)/1000) <= (mutation_prob/size()))
      representation[i] = possibilities[random(15)];
  score();
  if(not check()) pprintf("L from mutate\n");
}

/*
 * Helper Functions
 */
individual new_ind() {                         // randomly generate a new individual
  individual ind;
  int index = 0;
  char possibilities[16] = BUILDING_BLOCKS;
  ind.representation[0] = possibilities[random(15)];
  for(int i=0; i < random(IND_SIZE); ++i) {
    ind.representation[i] = possibilities[random(15)];
    index = i;
  }
  ind.representation[index+1] = '\0';
  ind.fitness = 0;
  ind.score();                                 // evaluate the fitness of the new individual
  if(not ind.check()) pprintf("L from new_ind\n");
  return ind;
}

#ifdef COEVOLVE
eval_individual new_eval_ind() {               // randomly generate a new individual
  eval_individual ind;
  ind.fitness = 0;
  ind.representation[0] = random(-CHECK_RANGE, CHECK_RANGE);
  for(int i=0; i < random(CHECK_SIZE); ++i) {
    ind.representation[i] = random(-CHECK_RANGE, CHECK_RANGE);
  }
  ind.score();                                 // evaluate the fitness
  return ind;
}
#endif

individual crossover(individual * mother, individual * father) {
  individual child;
  int index = 0;
  int mother_point = random(mother->size());
  int father_point = random(father->size());
  for(int i=0; i<mother_point; ++i) {
    child.representation[index] = mother->representation[i];
    ++index;
  }
  for(int i=father_point; i<father->size(); ++i) {
    if((index+1) >= (IND_SIZE - 1)) break;
    child.representation[index] = father->representation[i];
    ++index;
  }
  child.representation[index] = '\0';
  child.score();
  if(not child.check()) pprintf("L from crossover\n");
  return child;
}

#ifdef COEVOLVE
eval_individual eval_crossover(eval_individual * mother, eval_individual * father) {
  eval_individual child;
  int cross_point = random(CHECK_SIZE);
  for(int i=0; i<CHECK_SIZE; ++i) {
    if (i < cross_point)
      child.representation[i] = mother->representation[i];
    else
      child.representation[i] = father->representation[i];
    if(child.representation[i] > CHECK_RANGE ||
       child.representation[i] < -CHECK_RANGE)
      child.representation[i] = random(-CHECK_RANGE, CHECK_RANGE);
  }
  child.score();
  return child;
}
#endif

void share(individual * candidate) {
  pprintf("i %s\n", candidate->representation);
}

#ifdef COEVOLVE
void eval_share(eval_individual * candidate) {
  pprintf("e ");
  for(int i=0; i<CHECK_SIZE; ++i)
    pprintf("%d", candidate->representation[i]);
  pprintf("\n");
}
#endif

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
  void incorporate(individual ind);
  individual * tournament();
  individual breed();
  individual * best() {
    individual * best = &pop[0];
    for(int i=0; i<POP_SIZE; ++i)
      if(pop[i].fitness < best->fitness)
        best = &pop[i];
    return best;
  }
  double best_fitness() {
    double best = pop[0].fitness;
    for(int i=0; i<POP_SIZE; ++i) if (pop[i].fitness < best) best = pop[i].fitness;
    return best;
  }
  char * best_representation() {
    double best = pop[0].fitness;
    char * rep;
    for(int i=0; i<POP_SIZE; ++i) {
      if (pop[i].fitness < best) {
        best = pop[i].fitness;
        rep = pop[i].representation;
      }
    }
    return rep;
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
  if(ind.check()) {
    int worst_ind = 0;
    for(int i=0; i<POP_SIZE; ++i)
      if (pop[i].fitness > pop[worst_ind].fitness)
        worst_ind = i;
    pop[worst_ind] = ind;
  }
}
individual * population::tournament() {          // select individual with tournament of size SIZE
  int winner = random(POP_SIZE);
  int challenger = 0;
  for(int i=0; i<tournament_size; ++i) {
    challenger = random(POP_SIZE);
    if(pop[challenger].fitness < pop[winner].fitness)
      winner = challenger;
  }
  return & pop[winner];
}
individual population::breed() {               // breed two members returning a new individual
  return crossover(tournament(), tournament());
}
population pop;

#ifdef COEVOLVE
struct eval_population {
  eval_individual pop[EVAL_POP_SIZE];
  void rescore();
  void reset() {
    for(int i = 0; i < EVAL_POP_SIZE; ++i)
      pop[i] = new_eval_ind();
  }
  void incorporate(eval_individual ind);
  eval_individual * tournament();
  eval_individual breed();
  eval_individual * best() {
    eval_individual * best = &pop[0];
    for(int i=0; i<EVAL_POP_SIZE; ++i)
      if(pop[i].fitness > best->fitness)
        best = &pop[i];
    return best;
  }
  double best_fitness() {
    double best = pop[0].fitness;
    for(int i=0; i<EVAL_POP_SIZE; ++i) if (pop[i].fitness > best) best = pop[i].fitness;
    return best;
  }
  double mean_fitness() {
    double mean = 0;
    for(int i=0; i<EVAL_POP_SIZE; ++i) mean = mean + pop[i].fitness;
    return (mean / EVAL_POP_SIZE);
  }
};
void eval_population::rescore() {             // re-evaluate the fitness of every individual
  for(int i=0; i<EVAL_POP_SIZE; ++i)
    pop[i].score();
}
void eval_population::incorporate(eval_individual ind) { // add a new individual, evicting the worst
  int worst_ind = 0;
  for(int i=0; i<EVAL_POP_SIZE; ++i)
    if (pop[i].fitness < pop[worst_ind].fitness)
      worst_ind = i;
  pop[worst_ind] = ind;
}
eval_individual * eval_population::tournament() {  // select individual with tournament of size SIZE
  int winner = random(EVAL_POP_SIZE);
  int challenger = 0;
  for(int i=0; i<tournament_size; ++i) {
    challenger = random(EVAL_POP_SIZE);
    if(pop[challenger].fitness > pop[winner].fitness)
      winner = challenger;
  }
  return & pop[winner];
}
eval_individual eval_population::breed() {    // breed two members returning a new individual
  return eval_crossover(tournament(), tournament());
}
eval_population eval_pop;
#endif

/*
 * Scoring relies on the existence of the populations
 */
#ifndef COEVOLVE
double individual::score() {
  double fit = 0;
  double difference;
  int check_point = 0;
  for(int j=0; j<EVAL_POP_SIZE; ++j) {
    fit = 0;
    for(int i=0; i<CHECK_SIZE; ++i) {
      check_point = random(-CHECK_RANGE,CHECK_RANGE);
      difference = (evaluate(check_point, goal) -
                    evaluate(check_point, representation));
      if (difference < 0)
        difference = (0 - difference);
      fit = fit + difference;
    }
    update_fitness(fit);
  }
  return fitness;
}
#endif

#ifdef COEVOLVE
double individual::score() {
  double fit = 0;
  double difference;
  eval_individual eval;
  for(int j=0; j<EVAL_POP_SIZE; ++j) {
    eval = eval_pop.pop[j];
    fit = 0;
    for(int i=0; i<CHECK_SIZE; ++i) {
      difference = (evaluate(eval.representation[i], goal) -
                    evaluate(eval.representation[i], representation));
      if (difference < 0)
        difference = (0 - difference);
      fit = fit + difference;
    }
    eval.update_fitness(fit);
    update_fitness(fit);
  }
  return fitness;
}
double eval_individual::score() {
  double fit = 0;
  double difference;
  individual fodder;
  for(int j=0; j<POP_SIZE; ++j) {
    fodder = pop.pop[j];
    fit = 0;
    for(int i=0; i<CHECK_SIZE; ++i) {
      difference = (evaluate(representation[i], goal) -
                    evaluate(representation[i], fodder.representation));
      if (difference < 0)
        difference = (0 - difference);
      fit = fit + difference;
    }
    update_fitness(fit);
  }
  return fitness;
}
#endif

/*
 * Alarms (Mutation and Breeding) eventually (Sharing and Data collection)
 */
static void do_mutate(u32 when) {
  individual new_guy = pop.tournament()->copy();
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

#ifdef COEVOLVE
static void do_eval_mutate(u32 when) {
  eval_individual new_guy = eval_pop.tournament()->copy();
  new_guy.mutate();
  eval_pop.incorporate(new_guy);
  if(eval_mutation_tick > 0) {                 // don't reschedule if tick is 0
    if (when+eval_mutation_tick < millis()){
      pprintf("L eval_mutating too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    } else
      Alarms.set(Alarms.currentAlarmNumber(), when+eval_mutation_tick);
  }
}
#endif

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

#ifdef COEVOLVE
static void do_eval_breed(u32 when) {
  eval_pop.incorporate(eval_pop.breed());
  if(eval_breeding_tick > 0) {                 // don't reschedule if tick is 0
    if (when+eval_breeding_tick < millis()) {
      pprintf("L eval_breeding too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    } else
      Alarms.set(Alarms.currentAlarmNumber(), when+eval_breeding_tick);
  }
}
#endif

static void do_inject(u32 when) {
  pop.incorporate(new_ind());
  if(injection_tick > 0) {                     // don't reschedule if tick is 0
    if (when+injection_tick < millis()) {
      pprintf("L injecting too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    }
    else
      Alarms.set(Alarms.currentAlarmNumber(), when+injection_tick);
  }
}

#ifdef COEVOLVE
static void do_eval_inject(u32 when) {
  eval_pop.incorporate(new_eval_ind());
  if(eval_injection_tick > 0) {                // don't reschedule if tick is 0
    if (when+eval_injection_tick < millis()) {
      pprintf("L eval_injecting too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    }
    else
      Alarms.set(Alarms.currentAlarmNumber(), when+eval_injection_tick);
  }
}
#endif

static void do_share(u32 when) {
  share(pop.tournament());
  if(sharing_tick > 0) {                      // don't reschedule if tick is 0
    if (when+sharing_tick < millis()) {
      pprintf("L sharing too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    }
    else
      Alarms.set(Alarms.currentAlarmNumber(), when+sharing_tick);
  }
}

#ifdef COEVOLVE
static void do_eval_share(u32 when) {
  eval_share(eval_pop.tournament());
  if(eval_sharing_tick > 0) {                 // don't reschedule if tick is 0
    if (when+eval_sharing_tick < millis()) {
      pprintf("L eval_sharing too fast\n");
      Alarms.set(Alarms.currentAlarmNumber(), millis()+1000);
    }
    else
      Alarms.set(Alarms.currentAlarmNumber(), when+eval_sharing_tick);
  }
}
#endif


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
    QLED.on(BODY_RGB_RED_PIN, 500);
    QLED.off(BODY_RGB_RED_PIN, 100);
    goal_seconds = 0;
    pop.rescore();
    pprintf("g %s\n", goal);
    pprintf("L new goal is %s\n", goal);
  } else {                                        // indicate seen this before
    QLED.on(BODY_RGB_RED_PIN, 500);
    QLED.off(BODY_RGB_RED_PIN, 100);
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
    QLED.on(BODY_RGB_BLUE_PIN, 500);
    QLED.off(BODY_RGB_BLUE_PIN, 100);
  }
  pop.incorporate(ind);
}

#ifdef COEVOLVE
void acceptEvalIndividual(u8 * packet) {
  eval_individual ind;
  int index = 0;
  ind.fitness = -1;
  int point;
  if (packetScanf(packet, "i ") != 2) {
    pprintf("L bad individual: '%#p'\n",packet);
    return;
  }
  while((packetScanf(packet, "%d", &point)) && index < CHECK_SIZE) {
    ind.representation[index] = point;
    ++index;
  }
  ind.score();
  if(ind.fitness > pop.best_fitness()) {
    QLED.on(BODY_RGB_RED_PIN, 500);
    QLED.off(BODY_RGB_RED_PIN, 100);
  }
  eval_pop.incorporate(ind);
}
#endif

void reset() {
  pop.reset();                                 // randomly generate a population
#ifdef COEVOLVE
  eval_pop.reset();                            // randomly generate a new eval population
#endif
  if(mutation_tick > 0) {
    if(mutation_alarm_index < 0) {             // maybe begin the mutation alarm
      mutation_alarm_index = Alarms.create(do_mutate);
    }
    Alarms.set(mutation_alarm_index,millis() + 1000);
  }

#ifdef COEVOLVE
  if(eval_mutation_tick > 0) {
    if(eval_mutation_alarm_index < 0) {        // maybe begin the eval_mutation alarm
      eval_mutation_alarm_index = Alarms.create(do_eval_mutate);
    }
    Alarms.set(eval_mutation_alarm_index,millis() + 1000);
  }
#endif

  if(breeding_tick > 0) {
    if(breeding_alarm_index < 0) {             // maybe begin the breeding alarm
      breeding_alarm_index = Alarms.create(do_breed);
    }
    Alarms.set(breeding_alarm_index,millis() + 1250);
  }

#ifdef COEVOLVE
  if(eval_breeding_tick > 0) {
    if(eval_breeding_alarm_index < 0) {        // maybe begin the eval_breeding alarm
      eval_breeding_alarm_index = Alarms.create(do_eval_breed);
    }
    Alarms.set(eval_breeding_alarm_index,millis() + 1250);
  }
#endif

  if(injection_tick > 0) {
    if(injection_alarm_index < 0) {             // maybe begin the injection alarm
      injection_alarm_index = Alarms.create(do_inject);
    }
    Alarms.set(injection_alarm_index,millis() + 1000);
  }

#ifdef COEVOLVE
  if(eval_injection_tick > 0) {
    if(eval_injection_alarm_index < 0) {        // maybe begin the eval_injection alarm
      eval_injection_alarm_index = Alarms.create(do_eval_inject);
    }
    Alarms.set(eval_injection_alarm_index,millis() + 1000);
  }
#endif

  if(sharing_tick > 0) {
    if(sharing_alarm_index < 0) {             // maybe begin the sharing alarm
      sharing_alarm_index = Alarms.create(do_share);
    }
    Alarms.set(sharing_alarm_index,millis() + 1000);
  }

#ifdef COEVOLVE
  if(eval_sharing_tick > 0) {
    if(eval_sharing_alarm_index < 0) {        // maybe begin the eval_sharing alarm
      eval_sharing_alarm_index = Alarms.create(do_eval_share);
    }
    Alarms.set(eval_sharing_alarm_index,millis() + 1000);
  }
#endif

}

// reset packets look like "r m:10 b:0 ..."
void populationReset(u8 * packet) {
  if (packetScanf(packet, "r") != 1) {
    pprintf("L bad reset: '%#p'\n",packet);
    return;
  }
  // only allow population resets every 2 seconds
  if(goal_seconds > 2){
    goal_seconds = 0;
    char key;
    int val;
    while (packetScanf(packet, " %c:%d", &key, &val)) {
      switch(key) {
      case 'm': mutation_tick = val;   break;
      case 'b': breeding_tick = val;   break;
      case 'i': injection_tick = val;  break;
      case 's': sharing_tick = val;    break;
      case 't': tournament_size = val; break;
      case 'p': mutation_prob = val;   break;
#ifdef COEVOLVE
      case 'M': eval_mutation_tick = val;   break;
      case 'B': eval_breeding_tick = val;   break;
      case 'I': eval_injection_tick = val;  break;
      case 'S': eval_sharing_tick = val;    break;
      case 'T': eval_tournament_size = val; break;
      case 'P': eval_mutation_prob = val;   break;
#endif
      default: pprintf("L hork on key: %c\n", key);
      }
    }
    QLED.on(BODY_RGB_BLUE_PIN, 500);
    QLED.on(BODY_RGB_RED_PIN, 500);
    QLED.off(BODY_RGB_BLUE_PIN, 100);
    QLED.off(BODY_RGB_RED_PIN, 100);
    reset();
    pprintf("%#p\n", packet);
  }
}

void setup() {
  QLED.begin();
  // g xs55+55+**
  goal[0] = 'x';
  goal[1] = 's';
  goal[2] = '5';
  goal[3] = '5';
  goal[4] = '+';
  goal[5] = '5';
  goal[6] = '5';
  goal[7] = '+';
  goal[8] = '*';
  goal[9] = '*';
  goal[10] = '\0';

  collector_init();                            // initialize the collector
  Body.reflex('g', newGoal);                   // reset the goal function.
  Body.reflex('i', acceptIndividual);          // incorporate a neighbor's individual
#ifdef COEVOLVE
  Body.reflex('e', acceptEvalIndividual);      // incorporate a neighbor's evaluation individual
#endif
  Body.reflex('r', populationReset);           // reset the population (and settings)
  reset();
}

#ifdef COEVOLVE
eval_individual * eval_best;
#endif
void loop() {
  delay(1000); ++goal_seconds;

  // report best individual
  report_double(pop.best_fitness());
  report_string(pop.best()->representation);

#ifdef COEVOLVE
  // report best eval_individual
  eval_best = eval_pop.best();
  pprintf("k");
  facePrint(ALL_FACES, eval_best->fitness);
  pprintf(" \n");
  pprintf("k");
  for(int i=0; i<CHECK_SIZE; ++i)
    pprintf("%d ", eval_best->representation[i]);
  pprintf(" \n");
#endif

  if (buttonDown()) pop.reset();
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_4(c,o,e,v)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
