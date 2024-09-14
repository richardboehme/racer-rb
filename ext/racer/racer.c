#include "racer.h"

static VALUE tpCall = Qnil;
static pthread_t pthread;
static tiny_queue_t* tiny_queue;
static int flushed = 0;

static void
process_call_event(VALUE trace_point, void *data)
{
  rb_trace_arg_t* trace_arg = rb_tracearg_from_tracepoint(trace_point);

  const char* callee_id_original = rb_id2name(SYM2ID(rb_tracearg_callee_id(trace_arg)));
  const char* callee_path_original = RSTRING_PTR(rb_tracearg_path(trace_arg));
  long callee_lineno = FIX2LONG(rb_tracearg_lineno(trace_arg));
  const char* method_id_original = rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg)));

  VALUE method = rb_funcall(rb_tracearg_self(trace_arg), rb_intern("method"), 1, rb_tracearg_method_id(trace_arg));
  VALUE method_source = rb_funcall(method, rb_intern("source_location"), 0);

  const char* method_path_original = RSTRING_PTR(rb_ary_entry(method_source, 0));
  long method_lineno = FIX2LONG(rb_ary_entry(method_source, 1));

  // missing type information
  const char* original_return_type = rb_class2name(rb_class_of(rb_tracearg_return_value(trace_arg)));

  // VALUE params = rb_tracearg_parameters(trace_arg);

  ReturnTrace* call = (ReturnTrace*)malloc(sizeof(ReturnTrace));
  call->callee_id = strdup(callee_id_original);

  tiny_queue_message_t* message = (tiny_queue_message_t*) malloc(sizeof(tiny_queue_message_t));
  message->queue_state = 1;
  message->data = call;

  tiny_queue_push(tiny_queue, message);
}

static VALUE start(VALUE self) {
  tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL | RUBY_EVENT_C_CALL, process_call_event, NULL);

  rb_tracepoint_enable(tpCall);

  tiny_queue = tiny_queue_create();
  pthread_create(&pthread, NULL, init_worker, tiny_queue);

  return Qnil;
}


static VALUE stop(VALUE self) {
  rb_tracepoint_disable(tpCall);
  tpCall = Qnil;

  struct tiny_queue_message_t* message = (struct tiny_queue_message_t*) malloc(sizeof(struct tiny_queue_message_t));
  message->queue_state = 0;
  tiny_queue_push(tiny_queue, message);

  return Qnil;
}

static void flush_end(VALUE arg) {
  if(flushed == 1) return;

  pthread_join(pthread, NULL);
  tiny_queue_destroy(tiny_queue);
  flushed = 1;
}

static VALUE flush(VALUE self) {
  flush_end(self);
  return Qnil;
}

RUBY_FUNC_EXPORTED void Init_racer(void) {
  VALUE Racer = rb_define_module("Racer");

  rb_define_singleton_method(Racer, "start", start, 0);
  rb_define_singleton_method(Racer, "stop", stop, 0);
  rb_define_singleton_method(Racer, "flush", flush, 0);

  rb_set_end_proc(flush_end, Qnil);
}

