#include "worker.hh"
#include "unistd.h"
#include <sys/socket.h>

void write_constant(char* buffer, long buffer_size, int* end, Constant& constant) {
  *end += snprintf(buffer + *end, buffer_size - *end, ",\"%s\",%d,%ld", constant.name, constant.type, constant.path_size);
  for(auto i = 0; i < constant.path_size; ++i) {
    auto path_fragment = constant.path[i];
    *end += snprintf(buffer + *end, buffer_size - *end, ",\"%s\",%d", path_fragment.name, path_fragment.type);
  }
  *end += snprintf(buffer + *end, buffer_size - *end, ",%d", constant.generic_argument_count);
  for(auto i = 0; i < constant.generic_argument_count; ++i) {
    auto generic = constant.generic_arguments[i];
    *end += snprintf(buffer + *end, buffer_size - *end, ",%lu", generic.union_size);
    for(auto j = 0; j < generic.union_size; ++j) {
      write_constant(buffer, buffer_size, end, generic.union_types[j]);
    }
  }
}

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
    // method_name,return_type,owner_name,owner_type,namespace_size,[path_name,path_type,*],...
    auto end = snprintf(buffer, sizeof(buffer), "[\"%s\",%d", trace->method_name, trace->method_kind);
    write_constant(buffer, sizeof(buffer), &end, trace->return_type);
    write_constant(buffer, sizeof(buffer), &end, trace->method_owner);

    end += snprintf(buffer + end, sizeof(buffer) - end, ",%ld", trace->params_size);

    for (long i = 0; i < trace->params_size; ++i)
    {
      auto param = trace->params[i];
      end += snprintf(buffer + end, sizeof(buffer) - end, ",\"%s\",%d", param.name, param.param_type);

      write_constant(buffer, sizeof(buffer), &end, param.type_name);
    }
    buffer[end] = ']';
    buffer[++end] = '\n';

    if(send(socket_fd, buffer, end + 1, 0) < 0) {
      perror("socket send");
      return nullptr;
    }

    free(trace->method_name);
    // free(trace->return_type);
    // for(long i = 0; i < trace->params_size; ++i) {
    //   auto &param = trace->params[i];
    //   if(param.class_name) {
    //     free(param.class_name);
    //   }
    //   free(param.name);
    // }
    free(trace);
    free(message);
  }

  return nullptr;
}
