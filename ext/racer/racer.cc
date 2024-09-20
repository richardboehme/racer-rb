#include "racer.hh"

static VALUE tpCall = Qnil;
static pthread_t pthread;
static tiny_queue_t *tiny_queue;
static int flushed = 0;

static void
process_call_event(VALUE trace_point, void *data)
{
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point);

  ReturnTrace *call = (ReturnTrace *)malloc(sizeof(ReturnTrace));

  const char *callee_id_original = rb_id2name(SYM2ID(rb_tracearg_callee_id(trace_arg)));
  call->callee_id = strdup(callee_id_original);

  const char *callee_path_original = RSTRING_PTR(rb_tracearg_path(trace_arg));
  call->callee_path = strdup(callee_path_original);

  call->callee_lineno = FIX2LONG(rb_tracearg_lineno(trace_arg));

  const char *method_id_original = rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg)));
  call->method_id = strdup(method_id_original);

  VALUE method = rb_funcall(rb_tracearg_self(trace_arg), rb_intern("method"), 1, rb_tracearg_method_id(trace_arg));
  VALUE method_source = rb_funcall(method, rb_intern("source_location"), 0);

  if (RB_TEST(method_source))
  {
    const char *method_path_original = RSTRING_PTR(rb_ary_entry(method_source, 0));
    call->method_path = strdup(method_path_original);

    call->method_lineno = FIX2LONG(rb_ary_entry(method_source, 1));
  }
  else
  {
    call->method_path = nullptr;
    call->method_lineno = -1;
  }

  // rb_p(rb_tracearg_method_id(trace_arg));
  // rb_p(method);

  VALUE parameters = rb_funcall(method, rb_intern("parameters"), 0);
  char **params = (char **)malloc(sizeof(char *) * rb_array_len(parameters) * 2);
  VALUE binding = rb_tracearg_binding(trace_arg);

  // rb_p(parameters);
  // rb_p(LONG2FIX(rb_array_len(parameters)));
  for (long i = 0; i < rb_array_len(parameters); ++i)
  {
    VALUE param = rb_ary_entry(parameters, i);
    VALUE name = rb_ary_entry(param, 1);
    // const char *param_name = rb_id2name(SYM2ID(name));
    // params[i * 2] = strdup(param_name);
    // params[i * 2 + 1] = strdup(param_name);

    if (RB_TEST(rb_str_equal(rb_sym2str(rb_ary_entry(param, 0)), rb_str_new_cstr("req"))))
    {
      const char *param_name = rb_id2name(SYM2ID(name));
      params[i * 2] = strdup(param_name);
      params[i * 2 + 1] = strdup(param_name);

      // rb_p(name);
      // rb_p(rb_funcall(binding, rb_intern("local_variable_defined?"), 1, name));

      if (!RB_TEST(rb_funcall(binding, rb_intern("local_variable_defined?"), 1, name)))
      {
        rb_p(rb_tracearg_path(trace_arg));
        rb_p(rb_tracearg_lineno(trace_arg));
        rb_p(rb_tracearg_method_id(trace_arg));
        // TODO: There is some mystery here about callee vs method when retrieving the arguments
        // This might be auto-solved if we use the call event (which we need to anyway) to retrieve method params
        if (call->method_path)
        {
          rb_p(rb_str_new_cstr(call->method_path));
          rb_p(LONG2FIX(call->method_lineno));
        }
        rb_p(name);
      }

      // VALUE value = rb_funcall(binding, rb_intern("local_variable_get"), 1, name);
      // const char *param_class = rb_class2name(rb_class_of(value));
      // params[i * 2 + 1] = strdup(param_class);
    }
  }
  call->params_size = rb_array_len(parameters);
  call->params = params;

  // missing type information
  const char *original_return_type = rb_class2name(rb_class_of(rb_tracearg_return_value(trace_arg)));
  call->return_type = strdup(original_return_type);

  tiny_queue_message_t *message = (tiny_queue_message_t *)malloc(sizeof(tiny_queue_message_t));
  message->queue_state = 1;
  message->data = call;

  tiny_queue_push(tiny_queue, message);
}

static VALUE start(VALUE self)
{
  tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_RETURN, process_call_event, nullptr);

  rb_tracepoint_enable(tpCall);

  tiny_queue = tiny_queue_create();
  pthread_create(&pthread, nullptr, init_worker, tiny_queue);

  return Qnil;
}

static VALUE stop(VALUE self)
{
  rb_tracepoint_disable(tpCall);
  tpCall = Qnil;

  struct tiny_queue_message_t *message = (struct tiny_queue_message_t *)malloc(sizeof(struct tiny_queue_message_t));
  message->queue_state = 0;
  tiny_queue_push(tiny_queue, message);

  return Qnil;
}

static void flush_end(VALUE arg)
{
  if (flushed == 1 || !pthread || !tiny_queue)
    return;

  pthread_join(pthread, nullptr);
  tiny_queue_destroy(tiny_queue);
  flushed = 1;
}

static VALUE flush(VALUE self)
{
  flush_end(self);
  return Qnil;
}

extern "C" void
Init_racer(void)
{
  VALUE Racer = rb_define_module("Racer");

  rb_define_singleton_method(Racer, "start", start, 0);
  rb_define_singleton_method(Racer, "stop", stop, 0);
  rb_define_singleton_method(Racer, "flush", flush, 0);

  rb_set_end_proc(flush_end, Qnil);
}
