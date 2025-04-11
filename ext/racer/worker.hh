#ifndef WORKER_H
#define WORKER_H 1

#include <stdio.h>
#include "tiny_queue.hh"
#include "traces.hh"

typedef struct WorkerData {
  tiny_queue_t* queue;
  int socket_fd;
} WorkerData;

void *init_worker(void *);

#endif /* WORKER_H */
