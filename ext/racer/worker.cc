#include "worker.hh"
#include "unistd.h"

void *init_worker(void *arg)
{
  tiny_queue_t *tiny_queue = static_cast<tiny_queue_t *>(arg);

  fprintf(stderr, "printing from a thread!\n");

  FILE *f1 = fopen("out.csv", "w");

  tiny_queue_message_t *message;
  ReturnTrace *trace;

  while ((message = static_cast<tiny_queue_message_t *>(tiny_queue_pop(tiny_queue))))
  {
    if (message->queue_state == 0)
      break;

    trace = static_cast<ReturnTrace *>(message->data);
    fprintf(f1, "%s, %ld, %s, %s, %s, %ld", trace->callee_path, trace->callee_lineno, trace->callee_id, trace->method_id, trace->method_path, trace->method_lineno);
    for (long i = 0; i < trace->params_size; ++i)
    {
      fprintf(f1, ", [%s, %s]", trace->params[i * 2], trace->params[i * 2 + 1]);
    }
    fprintf(f1, "\n");

    // free(trace->callee_id);
    // free(trace->callee_path);
    // free(trace->method_id);
    // if (trace->method_path)
    //   free(trace->method_path);
    // free(trace->return_type);

    // for (long i = 0; i < trace->params_size; ++i)
    // {
    //   free(trace->params[i * 2]);
    //   free(trace->params[i * 2 + 1]);
    // }

    // free(trace);
    // free(message);
  }

  fclose(f1);

  return nullptr;
}
