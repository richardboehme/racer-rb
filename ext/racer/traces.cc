#include "traces.hh"
#include <stdlib.h>

void free_constant_instance(ConstantInstance& instance) {
  // Name is owned by "Constant" object

  if(instance.generic_arguments) {
    for(unsigned char i = 0; i < instance.generic_argument_count; ++i) {
      for(auto generic_argument : instance.generic_arguments[i]) {
        free_constant_instance(generic_argument);
      }
    }
    delete[] instance.generic_arguments;
  }
}

void free_param(Parameter& param) {
  if(param.name) {
    free(param.name);
  }

  free_constant_instance(param.type_name);
}

void free_block_param(BlockParameter& param) {
  if(param.name) {
    free(param.name);
  }

  for(auto trace : param.block_traces) {
    if(trace) {
      free_trace(trace);
    }
  }

  for(auto trace : param.current_block_call_stack) {
    if(trace) {
      free_trace(trace);
    }
  }
}

void free_trace(ReturnTrace* trace) {
  free_constant_instance(trace->method_owner);

  if(trace->method_callee.has_value()) {
    free_constant_instance(trace->method_callee.value());
  }

  if(trace->method_name) {
    free(trace->method_name);
  }

  free_constant_instance(trace->return_type);

  for(long i = 0; i < trace->params_size; ++i) {
    free_param(trace->params[i]);
  }
  delete[] trace->params;

  if(trace->block_param.has_value()) {
    free_block_param(trace->block_param.value());
  }

  if(trace->block_self_type.has_value()) {
    free_constant_instance(trace->block_self_type.value());
  }

  delete(trace);
}