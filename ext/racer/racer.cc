#include "racer.hh"
#include <sys/socket.h>
#include <sys/un.h>
#include <unordered_map>
#include <stack>
#include <unordered_set>
#include <vector>

#define DEBUG 0
#define debug_warn(fmt, ...) \
  do { if(DEBUG) rb_warn(fmt, __VA_ARGS__); } while(0)

static VALUE tpCall = Qnil;
static pthread_t pthread;
static tiny_queue_t *tiny_queue;
static int flushed = 0;
static int socketFd = 0;

static VALUE Racer = Qnil;

static ID reqParam, optParam, restParam, keyreqParam, keyParam, keyrestParam, nokeyParam, blockParam, anonRest, anonKeyrest, anonBlock, public_method_defined, private_method_defined = -1;

static std::unordered_map<long, std::stack<ReturnTrace*>> call_stacks;

static VALUE
class_to_name(VALUE klass) {
  auto class_name = rb_class_path_cached(rb_class_real(klass));
  if(RB_NIL_P(class_name)) {
    if(RB_TYPE_P(class_name, T_CLASS)) {
      do {
        klass = rb_class_superclass(klass);
        if(!RB_TEST(klass)) {
          break;
        }

        class_name = rb_class_path_cached(klass);
      } while(RB_NIL_P(class_name));
    } else {
      // Module
      return rb_str_new_cstr("Module");
    }
  }

  return class_name;
}

static ClassType
class_type_by_constant(VALUE constant) {
  auto type = rb_type(constant);

  if(type == T_CLASS) {
    return CLASS;
  } else
  if(type == T_MODULE) {
    return MODULE;
  } else {
    rb_warn("UNEXPECTED method owner type %d", type);
    return MODULE;
  }
}

static Constant
class_to_constant(VALUE klass, unsigned char generic_argument_size = 0, GenericArgument* generic_arguments = nullptr) {
  auto class_name = class_to_name(klass);
  auto current_space = rb_cObject;
  auto class_name_str = strdup(StringValueCStr(class_name));
  char* occurence = class_name_str;
  long constant_path_size = 0;
  do {
    occurence = strstr(occurence, "::");

    char* fragment;
    if(!occurence) break;

    occurence[0] = '\0';
    constant_path_size++;
    occurence += 2;
  } while(occurence != nullptr);

  auto paths = new Path[constant_path_size];

  for(auto i = 0; i < constant_path_size; ++i) {
    auto fragment = strdup(class_name_str);

    current_space = rb_const_get_at(current_space, rb_intern(fragment));
    paths[i] = { fragment, class_type_by_constant(current_space) };

    class_name_str += strlen(fragment) + 2;
  }

  return { strdup(StringValueCStr(class_name)), class_type_by_constant(klass), constant_path_size, paths, generic_argument_size, generic_arguments };
}

static GenericArgument
generic_argument_from_union_types(std::vector<VALUE>& types) {
  auto union_size = types.size();
  Constant* union_types = new Constant[union_size];

  for(size_t i = 0; i < union_size; ++i) {
    union_types[i] = class_to_constant(types.at(i));
  }

  return { union_size, union_types };
}

static int
hash_to_key_and_value_types(VALUE key, VALUE value, VALUE ary) {
  rb_ary_push(ary, rb_class_of(key));
  rb_ary_push(ary, rb_class_of(value));
  return ST_CONTINUE;
}

static void
process_call_event(rb_trace_arg_t *trace_arg)
{
  ReturnTrace *trace = (struct ReturnTrace *)malloc(sizeof(struct ReturnTrace));
  trace->rescued = false;

  auto method_id = rb_tracearg_method_id(trace_arg);
  trace->method_name = strdup(rb_id2name(SYM2ID(method_id)));
  trace->method_kind = INSTANCE;

  VALUE defined_class = rb_tracearg_defined_class(trace_arg);
  auto original_defined_class = defined_class;
  if(RB_FL_TEST_RAW(defined_class, FL_SINGLETON)) {
    VALUE tmp_defined_class = rb_class_attached_object(defined_class);
    auto type = rb_type(tmp_defined_class);
    if (type == T_MODULE || type == T_CLASS) {
      defined_class = tmp_defined_class;
      trace->method_kind = SINGLETON;
    } else {
      // TODO: Check if these cases can still happen or if we can safe the check before
    }
  }

  trace->method_owner = class_to_constant(defined_class);

  long fiber_id = rb_fiber_current();
  auto stack_pair = call_stacks.find(fiber_id);
  if(stack_pair != call_stacks.end()) {
    auto stack = (*stack_pair).second;
    if(!stack.empty()) {
      auto previous_trace = (*stack_pair).second.top();
      // Attempt to detect retries of a method using the `retry` keyword
      if(previous_trace->rescued && strcmp(trace->method_name, previous_trace->method_name) == 0 && strcmp(trace->method_owner.name, previous_trace->method_owner.name) == 0) {
        //fprintf(stderr, "[%ld] detected retry of method %s\n", fiber_id, trace->method_name);
        free(trace->method_name);
        free(trace);
        return;
      }
    }
  }

  // Qfalse == 0x0
  if(rb_funcall(original_defined_class, public_method_defined, 2, method_id, Qfalse)) {
    trace->method_visibility = PUBLIC;
  } else
  if(rb_funcall(original_defined_class, private_method_defined, 2, method_id, Qfalse)) {
    trace->method_visibility = PRIVATE;
  } else {
    trace->method_visibility = PROTECTED;
  }

  VALUE parameters = rb_tracearg_parameters(trace_arg); // We may be able to cache this for each method? or access the parsed stuff idk
  auto total_params_size = rb_array_len(parameters);
  trace->params_size = 0;
  // Array of character pointers, each even value is the param name, the following string is the type name
  trace->params = new Parameter[total_params_size];
  VALUE binding = rb_tracearg_binding(trace_arg);

  for (long i = 0; i < total_params_size; ++i)
  {
    VALUE param = rb_ary_entry(parameters, i);
    VALUE name = rb_ary_entry(param, 1);

    ID param_type = rb_sym2id(rb_ary_entry(param, 0));

    if (RB_TEST(name))
    {
      auto param_name_id = rb_sym2id(name);
      char *param_name = strdup(rb_id2name(SYM2ID(name)));
      VALUE param_class;

      unsigned char generic_argument_size = 0;
      GenericArgument* generic_arguments = nullptr;

      if(param_name_id == anonRest) {
        param_class = rb_cArray;
      } else
      if(param_name_id == anonKeyrest) {
        param_class = rb_cHash;
      } else
      if(param_name_id == anonBlock) {
        param_class = rb_cProc;
      } else {
        VALUE value = rb_funcall(binding, rb_intern("local_variable_get"), 1, name);
        param_class = rb_class_of(value);

        if (param_class == rb_cArray) {
          generic_argument_size = 1;
          // We need to use a set and a vector to preserve order of the union types
          std::unordered_set<VALUE> types = {};
          std::vector<VALUE> types_vec = {};
          auto ary_ptr = RARRAY_CONST_PTR(value);
          // This is O(n) and thus could be pretty slow
          for(auto j = 0; j < rb_array_len(value); ++j) {
            auto item = ary_ptr[j];

            auto klass = rb_class_of(item);
            auto result = types.insert(klass);
            if(result.second) {
              types_vec.push_back(klass);
            }
          }

          generic_arguments = new GenericArgument[1];
          generic_arguments[0] = generic_argument_from_union_types(types_vec);
        } else
        if(param_class == rb_cHash) {
          // RACER-TODO: I think we can optimize this, if the parameter is a keyword argument rest because
          // keys of those must be symbols, right?
          generic_argument_size = 2;
          std::unordered_set<VALUE> key_types = {};
          std::vector<VALUE> key_types_vec = {};
          std::unordered_set<VALUE> value_types = {};
          std::vector<VALUE> value_types_vec = {};

          auto hash_size = RHASH_SIZE(value);
          VALUE key_and_value_types = rb_ary_new_capa(hash_size * 2);
          rb_hash_foreach(value, hash_to_key_and_value_types, key_and_value_types);
          auto ary_ptr = RARRAY_CONST_PTR(key_and_value_types);

          // This is O(2n) and thus could be pretty slow
          for(auto j = 0; j < hash_size; ++j) {
            auto key_type = ary_ptr[j * 2];
            auto key_result = key_types.insert(key_type);
            if(key_result.second) {
              key_types_vec.push_back(key_type);
            }

            auto value_type = ary_ptr[j * 2 + 1];
            auto value_result = value_types.insert(value_type);
            if(value_result.second) {
              value_types_vec.push_back(value_type);
            }
          }

          generic_arguments = new GenericArgument[2];
          generic_arguments[0] = generic_argument_from_union_types(key_types_vec);
          generic_arguments[1] = generic_argument_from_union_types(value_types_vec);
        }
      }

      ParamType type;
      if(param_type == reqParam) {
        type = REQUIRED;
      } else
      if(param_type == optParam) {
        type = OPTIONAL;
      } else
      if(param_type == restParam) {
        type = REST;
      } else
      if(param_type == keyreqParam) {
        type = KEYWORD_REQUIRED;
      } else
      if(param_type == keyParam) {
        type = KEYWORD_OPTIONAL;
      } else
      if(param_type == keyrestParam) {
        type = KEYWORD_REST;
      } else
      if(param_type == blockParam) {
        type = BLOCK;
      } else {
        rb_warn("Unknown parameter type %s\n", rb_id2name(param_type));
        continue;
      }

      trace->params[trace->params_size] = { param_name, class_to_constant(param_class, generic_argument_size, generic_arguments), type };
      trace->params_size++;
    } else {
      if(param_type == nokeyParam) {
        // noKey means **nil which cannot be typed with RBS i think, so we ignore it for now
        continue;
      }

      if(param_type == reqParam) {
        // TODO: This is probably def foo((bar, foo)); end
        // Can we type this? If it only happens with arrays we might at least give information about it being an array? I wonder though how RBS
        // handles this in general. For the caller site the array type helps a bit, but inside the method this does not help at all and we have no parameter name
        continue;
      }

      auto inspected_params = rb_inspect(parameters);
      rb_warn("Unexpected: Parameter has no name for method %s, parameters: %s", trace->method_name, StringValueCStr(inspected_params));
    }
  }


  if(stack_pair == call_stacks.end()) {
    auto stack = std::stack<ReturnTrace*>();
    stack.push(trace);
    // fprintf(stderr, "[%ld] inserting method %s#%s\n", fiber_id, trace->method_owner_name, trace->method_name);
    call_stacks.insert({ fiber_id, stack });
  } else {
    // fprintf(stderr, "[%ld] pushing method %s#%s\n", fiber_id, trace->method_owner_name, trace->method_name);
    auto& stack = (*stack_pair).second;
    stack.push(trace);
  }
}

static void
process_return_event(rb_trace_arg_t* trace_arg) {
  long fiber_id = rb_fiber_current();

  auto stack_pair = call_stacks.find(fiber_id);
  if(stack_pair == call_stacks.end()) {
    // This might happen if another thread started calling before our TracePoint was enabled
    // or if Racer.start was called in a method that returns before Racer.stop was called
    debug_warn("[%ld] Unexpected: No callstack for return of %s", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
  } else {
    auto& stack = (*stack_pair).second;

    if(stack.empty()) {
      // This might happen if the method call that returns now activated our tracepoint
      rb_warn("[%ld] Unexpected: Call stack empty for method %s\n", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
      return;
    }

    auto trace = stack.top();
    if(!trace) {
      rb_warn("[%ld] Unexpected: Trace is null for method: %s", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
      return;
    }

    if(strcmp(trace->method_name, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg)))) != 0) {
      // This could happen if we return from a function for which we do not have a call recorded
      // def foo -> not recorded
      //   Racer.start
      // end -> recorded but no call stack entry
      rb_warn("[%ld] Return: Method mismatch, expected %s, got %s", fiber_id, trace->method_name, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
      return;
    }

    stack.pop();
    //fprintf(stderr, "[%ld] popped method %s#%s\n", fiber_id, trace->method_owner_name, trace->method_name);

    auto return_value = rb_tracearg_return_value(trace_arg);
    trace->return_type = class_to_constant(rb_class_of(return_value));

    tiny_queue_message_t *message = (tiny_queue_message_t *)malloc(sizeof(tiny_queue_message_t));
    message->queue_state = 1;
    message->data = trace;
    tiny_queue_push(tiny_queue, message);
  }
}

static void
process_rescued_event(rb_trace_arg_t* trace_arg) {
  long fiber_id = rb_fiber_current();

  auto stack_pair = call_stacks.find(fiber_id);
  if(stack_pair != call_stacks.end()) {
    auto& stack = (*stack_pair).second;

    if(stack.empty()) {
      // This might happen if the method call that returns now activated our tracepoint
      rb_warn("[%ld] Unexpected: Call stack empty for method %s\n", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
      return;
    }

    auto trace = stack.top();

    if(!trace) {
      rb_warn("[%ld] Unexpected: Trace is null for method: %s", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
      return;
    }

    if(strcmp(trace->method_name, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg)))) != 0) {
      // If these do not match the rescue happens inside a block and not inside the method. The method is not being retried in this case so we ignore this event.
      return;
    }

    auto exception = rb_inspect(rb_tracearg_raised_exception(trace_arg));
    //fprintf(stderr, "[%ld] setting rescued to true for method %s#%s, exception: %s\n", fiber_id, trace->method_name, trace->method_owner_name, StringValueCStr(exception));
    trace->rescued = true;
  }
}

static void
process_tracepoint(VALUE trace_point, void *data)
{
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point);
  switch(rb_tracearg_event_flag(trace_arg)) {
  case RUBY_EVENT_CALL:
    process_call_event(trace_arg);
    break;
  case RUBY_EVENT_RETURN:
    process_return_event(trace_arg);
    break;
  case RUBY_EVENT_RESCUE:
    process_rescued_event(trace_arg);
    break;
  }
}

static VALUE start(VALUE self)
{
  if(!RB_NIL_P(tpCall)) {
    rb_tracepoint_enable(tpCall);
    return Qnil;
  }

  socketFd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (socketFd < 0) {
    // handle error
    perror("socket");
    return Qnil;
  }

  struct sockaddr_un sockaddr;
  sockaddr.sun_family = AF_UNIX;
  auto path = "/tmp/racer.sock";
  strcpy(sockaddr.sun_path, path);

  if (connect(socketFd, (struct sockaddr*) &sockaddr, sizeof(sockaddr)) < 0) {
    perror("connect");
    // This ensures that we can still flush, even if the socket connection did not work out.
    // We may want to add more sophisticated error handling.
    socketFd = 0;
    return Qnil;
  }

  tiny_queue = tiny_queue_create();
  auto *worker_data = (struct WorkerData*) malloc(sizeof(struct WorkerData));
  worker_data->queue = tiny_queue;
  worker_data->socket_fd = socketFd;
  pthread_create(&pthread, nullptr, init_worker, worker_data);

  tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL | RUBY_EVENT_RETURN | RUBY_EVENT_RESCUE, process_tracepoint, nullptr);
  rb_tracepoint_enable(tpCall);

  return Qnil;
}

static VALUE stop(VALUE self)
{
  if(RB_TEST(tpCall)) {
    rb_tracepoint_disable(tpCall);
  }

  for(auto &stack_pair : call_stacks) {
    auto &stack = stack_pair.second;
    while(!stack.empty()) {
      auto trace = stack.top();
      stack.pop();

      // TODO: Implement free_trace or deconstructor? (free method owner)
      free(trace->method_name);
      for(long i = 0; i < trace->params_size; ++i) {
        auto param = trace->params[i];
        // if(param.class_name) {
        //   free(param.class_name);
        // }
        free(param.name);
      }

      assert(!trace->return_type);

      free(trace);
    }
  }
  call_stacks.clear();

  return Qnil;
}

static void flush_end(VALUE arg)
{
  if (flushed == 1 || socketFd <= 0)
    return;

  flushed = 1;

  stop(arg);
  tpCall = Qnil;

  struct tiny_queue_message_t *message = (struct tiny_queue_message_t *)malloc(sizeof(struct tiny_queue_message_t));
  message->queue_state = 0;
  tiny_queue_push(tiny_queue, message);

  pthread_join(pthread, nullptr);
  tiny_queue_destroy(tiny_queue);

  const char* buffer = "stop";
  if(send(socketFd, buffer, sizeof(buffer), 0) < 0) {
    perror("socket send flush");
  }

  close(socketFd);
  fprintf(stdout, "flushed\n");
}

static VALUE flush(VALUE self)
{
  flush_end(self);
  return Qnil;
}

extern "C" void
Init_racer(void)
{
  Racer = rb_define_module("Racer");

  reqParam = rb_intern("req");
  optParam = rb_intern("opt");
  restParam = rb_intern("rest");
  keyreqParam = rb_intern("keyreq");
  keyParam = rb_intern("key");
  keyrestParam = rb_intern("keyrest");
  nokeyParam = rb_intern("nokey");
  blockParam = rb_intern("block");
  anonRest = rb_intern("*");
  anonKeyrest = rb_intern("**");
  anonBlock = rb_intern("&");
  public_method_defined = rb_intern("public_method_defined?");
  private_method_defined = rb_intern("private_method_defined?");
  rb_global_variable(&tpCall);

  rb_define_singleton_method(Racer, "start", start, 0);
  rb_define_singleton_method(Racer, "stop", stop, 0);
  rb_define_singleton_method(Racer, "flush", flush, 0);
}
