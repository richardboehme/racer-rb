#include "worker.h"
#include "unistd.h"

void *init_worker(void* arg) {
  tiny_queue_t* tiny_queue = arg;

  fprintf(stderr, "printing from a thread!\n");

  tiny_queue_message_t* message;
  ReturnTrace* trace;

  while((message = tiny_queue_pop(tiny_queue))) {
    if(message->queue_state == 0) break;

    trace = message->data;
    printf("Received trace %s\n", trace->callee_id);
    free(trace->callee_id);
    free(trace);
    free(message);
  }

  return NULL;
}