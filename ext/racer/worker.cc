#include "worker.hh"
#include "unistd.h"
#include <sys/socket.h>

void *init_worker(void *arg)
{
  auto *worker_data = static_cast<WorkerData *>(arg);
  auto *tiny_queue = worker_data->queue;
  auto socket_fd = worker_data->socket_fd;

  // Worker Data is being allocated by the main thread
  free(worker_data);

  tiny_queue_message_t *message;
  ReturnTrace *trace;

  while (true)
  {
    message = static_cast<tiny_queue_message_t *>(tiny_queue_pop(tiny_queue));
    if (message->queue_state == 0)
      break;

    trace = static_cast<ReturnTrace *>(message->data);

    // TODO: If a method has lots of parameters this buffer will not be large enough
    char buffer[1024];
    auto end = snprintf(buffer, sizeof(buffer), "%s,%s,%s", trace->method_owner_name, trace->method_owner_type, trace->method_name);
    for (long i = 0; i < trace->params_size; ++i)
    {
      end += snprintf(buffer + end, sizeof(buffer) - end, ",%s,%s", trace->params[i * 2], trace->params[i * 2 + 1]);
    }
    buffer[end] = '\n';

    if(send(socket_fd, buffer, end + 1, 0) < 0) {
      perror("socket send");
    }

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

  return nullptr;
}
