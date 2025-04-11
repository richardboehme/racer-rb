#include "racer.hh"
#include <sys/socket.h>
#include <sys/un.h>

static VALUE tpCall = Qnil;
static pthread_t pthread;
static tiny_queue_t *tiny_queue;
static int flushed = 0;
static int socketFd = 0;

static VALUE Racer = Qnil;

static VALUE reqString = Qnil;

static void
process_call_event(VALUE trace_point, void *data)
{
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point);

  ReturnTrace *trace = (struct ReturnTrace *)malloc(sizeof(struct ReturnTrace));

  trace->method_name = strdup(rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));

  VALUE defined_class = rb_tracearg_defined_class(trace_arg);
  trace->method_owner_name = strdup(rb_class2name(defined_class));
  trace->method_owner_type = strdup(rb_class2name(rb_class_of(defined_class)));

  VALUE parameters = rb_tracearg_parameters(trace_arg);
  auto total_params_size = rb_array_len(parameters);
  trace->params_size = 0;
  // Array of character pointers, each even value is the param name, the following string is the type name
  trace->params = (char **)malloc(sizeof(char *) * total_params_size * 2);
  VALUE binding = rb_tracearg_binding(trace_arg);

  for (long i = 0; i < total_params_size; ++i)
  {
    VALUE param = rb_ary_entry(parameters, i);
    VALUE name = rb_ary_entry(param, 1);

    if (RB_TEST(rb_str_equal(rb_sym2str(rb_ary_entry(param, 0)), reqString)) && RB_TEST(name))
    {
      const char *param_name = rb_id2name(SYM2ID(name));
      trace->params[i * 2] = strdup(param_name);

      VALUE value = rb_funcall(binding, rb_intern("local_variable_get"), 1, name);
      const char *param_class = rb_class2name(rb_class_of(value));
      trace->params[i * 2 + 1] = strdup(param_class);
      trace->params_size++;
    }
  }

  tiny_queue_message_t *message = (tiny_queue_message_t *)malloc(sizeof(tiny_queue_message_t));
  message->queue_state = 1;
  message->data = trace;

  tiny_queue_push(tiny_queue, message);
}

static VALUE start(VALUE self)
{
  if(!RB_NIL_P(tpCall)) {
    rb_tracepoint_enable(tpCall);
    return Qnil;
  }

  tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL, process_call_event, nullptr);

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

  reqString = rb_str_new_cstr("req");
  rb_global_variable(&tpCall);
  rb_global_variable(&reqString);

  rb_define_singleton_method(Racer, "start", start, 0);
  rb_define_singleton_method(Racer, "stop", stop, 0);
  rb_define_singleton_method(Racer, "flush", flush, 0);
}
