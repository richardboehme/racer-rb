#include "racer.hh"
#include <sys/socket.h>
#include <sys/un.h>

static VALUE tpCall = Qnil;
static pthread_t pthread;
static tiny_queue_t *tiny_queue;
static int flushed = 0;
static int socketFd = 0;

static VALUE Racer = Qnil;

static void
process_call_event(VALUE trace_point, void *data)
{
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point);

  // const char *callee_id = rb_id2name(SYM2ID(rb_tracearg_callee_id(trace_arg)));
  // const char *callee_path = RSTRING_PTR(rb_tracearg_path(trace_arg));
  // const auto callee_lineno = FIX2LONG(rb_tracearg_lineno(trace_arg));
  const char *method_id = rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg)));

  VALUE method = rb_funcall(rb_tracearg_self(trace_arg), rb_intern("method"), 1, rb_tracearg_method_id(trace_arg));
  // VALUE method_source = rb_funcall(method, rb_intern("source_location"), 0);
  VALUE method_owner = rb_funcall(method, rb_intern("owner"), 0);
  const char *method_owner_name = rb_class2name(method_owner);
  const char *method_owner_type = rb_class2name(rb_class_of(method_owner));

  // const char* method_path = nullptr;
  // long method_lineno = -1;
  // if (RB_TEST(method_source))
  // {
  //   method_path = RSTRING_PTR(rb_ary_entry(method_source, 0));
  //   method_lineno = FIX2LONG(rb_ary_entry(method_source, 1));
  // }


  VALUE parameters = rb_tracearg_parameters(trace_arg);
  auto params_size = rb_array_len(parameters);
  // Array of character pointers, each even value is the param name, the following string is the type name
  char **params = (char **)malloc(sizeof(char *) * params_size * 2);
  VALUE binding = rb_tracearg_binding(trace_arg);

  for (long i = 0; i < params_size; ++i)
  {
    VALUE param = rb_ary_entry(parameters, i);
    VALUE name = rb_ary_entry(param, 1);

    if (RB_TEST(rb_str_equal(rb_sym2str(rb_ary_entry(param, 0)), rb_str_new_cstr("req"))))
    {
      const char *param_name = rb_id2name(SYM2ID(name));
      params[i * 2] = strdup(param_name);

      VALUE value = rb_funcall(binding, rb_intern("local_variable_get"), 1, name);
      const char *param_class = rb_class2name(rb_class_of(value));
      params[i * 2 + 1] = strdup(param_class);
    }
  }
  //params_size = 0;
  char buffer[1024];

  auto end = snprintf(buffer, sizeof(buffer), "%s,%s", method_owner_name, method_owner_type);
  for (long i = 0; i < params_size; ++i)
  {
    end += snprintf(buffer + end, sizeof(buffer), ",%s,%s", params[i * 2], params[i * 2 + 1]);
  }
  buffer[end] = '\n';

  if(send(socketFd, buffer, end + 1, 0) < 0) {
    perror("socket send");
  }
}

static VALUE start(VALUE self)
{
  tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL, process_call_event, nullptr);

  socketFd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (socketFd < 0) {
    // handle error
    perror("socket");
  }

  struct sockaddr_un sockaddr;
  sockaddr.sun_family = AF_UNIX;
  auto path = "/tmp/racer.sock";
  strcpy(sockaddr.sun_path, path);


  if (connect(socketFd, (struct sockaddr*) &sockaddr, sizeof(sockaddr)) < 0) {
    perror("connect");
  }

  rb_tracepoint_enable(tpCall);

  return Qnil;
}

static VALUE stop(VALUE self)
{
  rb_tracepoint_disable(tpCall);
  tpCall = Qnil;

  return Qnil;
}

static void flush_end(VALUE arg)
{
  if (flushed == 1 || socketFd == -1)
    return;

  flushed = 1;

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

  rb_define_singleton_method(Racer, "start", start, 0);
  rb_define_singleton_method(Racer, "stop", stop, 0);
  rb_define_singleton_method(Racer, "flush", flush, 0);
}
