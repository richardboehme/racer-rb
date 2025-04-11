#include "racer.hh"
#include <sys/socket.h>
#include <sys/un.h>
#include <unordered_map>
#include <stack>

static VALUE tpCall = Qnil;
static pthread_t pthread;
static tiny_queue_t *tiny_queue;
static int flushed = 0;
static int socketFd = 0;

static VALUE Racer = Qnil;

static ID reqParam, optParam, restParam, keyreqParam, keyParam, keyrestParam, blockParam, anonRest, anonKeyrest, anonBlock = -1;

static std::unordered_map<long, std::stack<ReturnTrace*>> call_stacks;

static void
process_call_event(rb_trace_arg_t *trace_arg)
{
  ReturnTrace *trace = (struct ReturnTrace *)malloc(sizeof(struct ReturnTrace));

  trace->method_name = strdup(rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));

  VALUE defined_class = rb_tracearg_defined_class(trace_arg);
  trace->method_owner_name = strdup(rb_class2name(defined_class));
  trace->method_owner_type = strdup(rb_class2name(rb_class_of(defined_class)));

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
      const char *param_name = rb_id2name(SYM2ID(name));
      const char *param_class;

      if(param_name_id != anonRest && param_name_id != anonKeyrest && param_name_id != anonBlock) {
        VALUE value = rb_funcall(binding, rb_intern("local_variable_get"), 1, name);
        param_class = strdup(rb_class2name(rb_class_of(value)));
      } else {
        param_class = nullptr;
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

      trace->params[i] = { param_name, param_class, type };
      trace->params_size++;
    } else {
      rb_p(rb_str_new_cstr("PARAMETER WITHOUT NAME?"));
      rb_p(param);
    }
  }

  long  fiber_id = rb_fiber_current();

  auto stack = call_stacks.find(fiber_id);
  if(stack == call_stacks.end()) {
    call_stacks.insert({ fiber_id, std::stack<ReturnTrace*>({trace}) });
  } else {
    (*stack).second.push(trace);
  }

  // tiny_queue_message_t *message = (tiny_queue_message_t *)malloc(sizeof(tiny_queue_message_t));
  // message->queue_state = 1;
  // message->data = trace;

  // tiny_queue_push(tiny_queue, message);
}

static void
process_return_event(rb_trace_arg_t* trace_arg) {
  long fiber_id = rb_fiber_current();

  auto stack = call_stacks.find(fiber_id);
  if(stack == call_stacks.end()) {
    rb_warn("Unexpected: No value in callstack for return of %s\n", rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
  } else {
    auto trace = (*stack).second.top();
    (*stack).second.pop();

    trace->return_type = strdup(rb_class2name(rb_class_of((rb_tracearg_return_value(trace_arg)))));

    tiny_queue_message_t *message = (tiny_queue_message_t *)malloc(sizeof(tiny_queue_message_t));
    message->queue_state = 1;
    message->data = trace;
    tiny_queue_push(tiny_queue, message);
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
  }
}

static VALUE start(VALUE self)
{
  if(!RB_NIL_P(tpCall)) {
    rb_tracepoint_enable(tpCall);
    return Qnil;
  }

  tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL | RUBY_EVENT_RETURN, process_tracepoint, nullptr);

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
    return Qnil;
  }

  tiny_queue = tiny_queue_create();
  auto *worker_data = (struct WorkerData*) malloc(sizeof(struct WorkerData));
  worker_data->queue = tiny_queue;
  worker_data->socket_fd = socketFd;
  pthread_create(&pthread, nullptr, init_worker, worker_data);

  rb_tracepoint_enable(tpCall);

  return Qnil;
}

static VALUE stop(VALUE self)
{
  rb_tracepoint_disable(tpCall);

  return Qnil;
}

static void flush_end(VALUE arg)
{
  if (flushed == 1 || socketFd == -1)
    return;

  flushed = 1;

  if(RB_TEST(tpCall)) {
    stop(arg);
    tpCall = Qnil;
  }

  struct tiny_queue_message_t *message = (struct tiny_queue_message_t *)malloc(sizeof(struct tiny_queue_message_t));
  message->queue_state = 0;
  tiny_queue_push(tiny_queue, message);

  pthread_join(pthread, nullptr);
  tiny_queue_destroy(tiny_queue);

  const char* buffer = "stop\n";
  if(send(socketFd, buffer, sizeof(buffer), 0) < 0) {
    perror("socket send flush");
  }

  close(socketFd);
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
  blockParam = rb_intern("block");
  anonRest = rb_intern("*");
  anonKeyrest = rb_intern("**");
  anonBlock = rb_intern("&");
  rb_global_variable(&tpCall);

  rb_define_singleton_method(Racer, "start", start, 0);
  rb_define_singleton_method(Racer, "stop", stop, 0);
  rb_define_singleton_method(Racer, "flush", flush, 0);
}
