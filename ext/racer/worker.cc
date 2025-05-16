#include "worker.hh"
#include "unistd.h"
#include <sys/socket.h>
#include <json-c/json.h>

void write_constant(json_object* json_array, std::shared_ptr<Constant> constant) {
  json_object_array_add(json_array, json_object_new_string(constant->name));
  json_object_array_add(json_array, json_object_new_boolean(constant->anonymous));
  json_object_array_add(json_array, json_object_new_int(constant->type));

  if(constant->superclass.has_value()) {
    json_object_array_add(json_array, json_object_new_string(constant->superclass.value()));
  } else {
    json_object_array_add(json_array, json_object_new_null());
  }

  json_object_array_add(json_array, json_object_new_uint64(constant->included_modules.size()));
  for(auto name : constant->included_modules) {
    json_object_array_add(json_array, json_object_new_string(name));
  }

  json_object_array_add(json_array, json_object_new_uint64(constant->prepended_modules.size()));
  for(auto name : constant->prepended_modules) {
    json_object_array_add(json_array, json_object_new_string(name));
  }

  json_object_array_add(json_array, json_object_new_uint64(constant->extended_modules.size()));
  for(auto name : constant->extended_modules) {
    json_object_array_add(json_array, json_object_new_string(name));
  }
}

void write_constant_instance(json_object* json_array, ConstantInstance& instance) {
  json_object_array_add(json_array, json_object_new_string(instance.name));
  json_object_array_add(json_array, json_object_new_boolean(instance.singleton));
  json_object_array_add(json_array, json_object_new_uint64(instance.generic_argument_count));
  for(int i = 0; i < instance.generic_argument_count; ++i) {
    json_object_array_add(json_array, json_object_new_uint64(instance.generic_arguments[i].size()));
    for(auto generic_instance : instance.generic_arguments[i]) {
      write_constant_instance(json_array, generic_instance);
    }
  }
}

int size_of_constant(std::shared_ptr<Constant> constant) {
  return 7 + constant->included_modules.size() + constant->prepended_modules.size() + constant->extended_modules.size();
}

int size_of_constant_updates(std::vector<std::shared_ptr<Constant>> &constant_updates) {
  auto size = 1;
  for(auto constant : constant_updates) {
    size += size_of_constant(constant);
  }
  return size;
}

int size_of_constant_instance(ConstantInstance& instance) {
  auto size = 3 + instance.generic_argument_count;
  for(int i = 0; i < instance.generic_argument_count; ++i) {
    for(auto generic_instance : instance.generic_arguments[i]) {
      size += size_of_constant_instance(generic_instance);
    }
  }
  return size;
}

int size_of_block_trace(ReturnTrace*);

int size_of_params(ReturnTrace* trace) {
  auto size = 1 + trace->params_size * 3;

  if(trace->block_param.has_value()) {
    size += 2;
    for(auto block_trace : (*(trace->block_param)).block_traces) {
      size += size_of_block_trace(block_trace);
    }
  }
  return size;
}

int size_of_block_trace(ReturnTrace* trace) {
  return 2 + size_of_params(trace);
}

void write_params(json_object*, ReturnTrace*);

void write_block_trace(json_object* json_array, ReturnTrace* trace) {
  write_constant_instance(json_array, trace->block_self_type.value());
  write_constant_instance(json_array, trace->return_type);
  write_params(json_array, trace);
}

void write_params(json_object* json_array, ReturnTrace* trace) {
  json_object_array_add(json_array, json_object_new_int64(trace->params_size));

  for (long i = 0; i < trace->params_size; ++i)
  {
    auto param = trace->params[i];
    if(param.name) {
      json_object_array_add(json_array, json_object_new_string(param.name));
    } else {
      json_object_array_add(json_array, json_object_new_null());
    }
    json_object_array_add(json_array, json_object_new_int(param.param_type));
    write_constant_instance(json_array, param.type_name);
  }

  if(trace->block_param.has_value()) {
    auto block_param = *(trace->block_param);
    if(block_param.name) {
      json_object_array_add(json_array, json_object_new_string(block_param.name));
    } else {
      json_object_array_add(json_array, json_object_new_null());
    }
    json_object_array_add(json_array, json_object_new_uint64(block_param.block_traces.size()));
    for(auto block_trace : block_param.block_traces) {
      write_block_trace(json_array, block_trace);
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

    auto array_size = 2 + size_of_constant_instance(trace->return_type) + size_of_constant_instance(trace->method_owner) + size_of_params(trace) + size_of_constant_updates(trace->constant_updates);
    if(trace->method_callee.has_value()) {
      array_size += size_of_constant_instance(trace->method_callee.value());
    } else {
      array_size += 1;
    }

    auto* json_array = json_object_new_array_ext(array_size);

    // method_name,return_type,owner_name,owner_type,namespace_size,[path_name,path_type,*],...
    json_object_array_add(json_array, json_object_new_string(trace->method_name));
    json_object_array_add(json_array, json_object_new_int(trace->method_kind));
    json_object_array_add(json_array, json_object_new_int(trace->method_visibility));

    write_constant_instance(json_array, trace->return_type);
    write_constant_instance(json_array, trace->method_owner);
    if(trace->method_callee.has_value()) {
      write_constant_instance(json_array, trace->method_callee.value());
    } else {
      json_object_array_add(json_array, json_object_new_null());
    }

    json_object_array_add(json_array, json_object_new_uint64(trace->constant_updates.size()));
    for(auto constant : trace->constant_updates) {
      write_constant(json_array, constant);
    }

    write_params(json_array, trace);

    auto json_string = json_object_to_json_string_ext(json_array, JSON_C_TO_STRING_PLAIN);

    if(send(socket_fd, json_string, strlen(json_string) + 1, 0) < 0) {
      perror("socket send");
      return nullptr;
    }

    json_object_put(json_array);

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
