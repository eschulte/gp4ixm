/*                                             -*- mode:C++ -*-
 *
 * Sketch description: Run GP on a single ixm board.
 * 
 * Sketch author: Eric Schulte
 *
 */
#define POP_SIZE 24
#define IND_SIZE 24

struct individual {
  char representation[IND_SIZE];
  double fitness;
  void evaluate();
};
void individual::evaluate () {
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
  ind.fitness = -1;
  char possibilities[15] = "0123456789+-*/";
  for(int i = 0; i < IND_SIZE; ++i)
    ind.representation[i] = possibilities[random(14)];
  return ind;
}

void setup() {
  // randomly generate a population
  for(int i = 0; i < POP_SIZE; ++i)
    pop.pop[i] = new_ind();
}

void loop() {
  delay(1000);
  ledToggle(BODY_RGB_BLUE_PIN);         // heartbeat
  int index = random(14);
  pprintf("random individual %d is %s\n", index, pop.pop[index].representation);
}

#define SFB_SKETCH_CREATOR_ID B36_3(e,m,s)
#define SFB_SKETCH_PROGRAM_ID B36_3(c,o,l)
#define SFB_SKETCH_COPYRIGHT_NOTICE "GPL V3"
