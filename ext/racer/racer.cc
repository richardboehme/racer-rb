#include "racer.hh"
#include <sys/socket.h>
#include <sys/un.h>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <memory>

#define DEBUG 0
#define debug_warn(fmt, ...) \
  do { if(DEBUG) rb_warn(fmt, __VA_ARGS__); } while(0)

static VALUE tpCall = Qnil;
static pthread_t pthread;
static tiny_queue_t *tiny_queue;
static int flushed = 0;
static int socketFd = 0;

static VALUE Racer = Qnil;
static VALUE pathMatcher = Qnil;
static long maxGenericDepth = 1;

static ID reqParam, optParam, restParam, keyreqParam, keyParam, keyrestParam, nokeyParam, blockParam, anonRest, anonKeyrest, anonBlock,
  method_defined, public_method_defined, private_method_defined,
  callerLocationsId, pathId = -1;

static std::unordered_map<unsigned long, std::vector<ReturnTrace*>> call_stacks;

// TODO: Think about if this can break with GCs. Currently we are not marking those objects so the GC
// cannot know if we hold a reference to them. Also with GC compaction the object behind a pointer
// could move (as far as I understand, CRuby prevents this for C-Extensions).
static std::unordered_map<VALUE, std::shared_ptr<Constant>> constant_map = {};
static std::vector<VALUE> constant_updates {};

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


static std::shared_ptr<Constant>
explore_constant(VALUE ruby_constant, std::unordered_set<VALUE> *visited_constants = nullptr) {
  // TODO: Should we check if we are already in the map here?
  auto constant_type = class_type_by_constant(ruby_constant);

  VALUE class_path = rb_class_path(ruby_constant);

  VALUE ruby_constant_name = rb_mod_name(ruby_constant);
  bool anonymous = false;
  if(RB_NIL_P(ruby_constant_name)) {
    anonymous = true;
    VALUE klass = ruby_constant;
    if(RB_TYPE_P(klass, T_CLASS)) {
      do {
        klass = rb_class_superclass(klass);
        if(!RB_TEST(klass)) {
          break;
        }

        ruby_constant_name = rb_class_path_cached(klass);
      } while(RB_NIL_P(ruby_constant_name));
    } else {
      // Module
      ruby_constant_name = rb_str_new_cstr("Module");
    }
  }
  auto constant_name = strdup(StringValueCStr(ruby_constant_name));

  Constant constant_obj = { constant_name, anonymous, constant_type };
  std::shared_ptr<Constant> constant = std::make_shared<Constant>(constant_obj);
  auto ancestors = rb_mod_ancestors(ruby_constant);

  // Object is the superclass of all classes (except BasicObject)
  VALUE stop_object = rb_cObject;
  if(stop_object == ruby_constant) {
    // The supplied constant is object
    stop_object = rb_mKernel;
  }

  auto ancestors_pointer = RARRAY_CONST_PTR(ancestors);
  bool prepended = false;
  std::unordered_set<VALUE> inner_constants = {};
  for(auto i = 0; i < rb_array_len(ancestors); ++i) {
    auto ancestor = ancestors_pointer[i];

    if(ancestor == ruby_constant) {
      // barrier from prepended to included/superclass
      prepended = false;
      continue;
    }

    if(ancestor == stop_object) {
      break;
    }

    if(constant_type == CLASS && rb_type_p(ancestor, T_CLASS)) {
      if(prepended) {
        auto ancestor_inspect = rb_inspect(ancestor);
        rb_warn("Class %s in ancestors of %s before self (prepended class?)", StringValueCStr(ancestor_inspect), constant_name);
        continue;
      }

      auto ancestor_constant = explore_constant(ancestor);
      constant->superclass = ancestor_constant->name;
      // After the superclass there will be other superclasses or modules included in the super classes
      // which are not directly included into constant. This means when reaching the superclass we reached
      // the end of constant's direct ancestor chain
      break;
    }

    // Constant is a module
    if(inner_constants.find(ancestor) == inner_constants.end()) {
      auto ancestor_constant = explore_constant(ancestor, &inner_constants);
      if(visited_constants) visited_constants->emplace(ancestor);

      if(prepended) {
        constant->prepended_modules.push_back(ancestor_constant->name);
      } else {
        constant->included_modules.push_back(ancestor_constant->name);
      }
    }
  }

  auto singleton_class = rb_singleton_class(ruby_constant);
  auto singleton_class_ancestors = rb_mod_ancestors(singleton_class);
  auto singleton_class_ancestors_pointer = RARRAY_CONST_PTR(singleton_class_ancestors);

  auto object_singleton_class = rb_singleton_class(rb_cObject);

  // Note: In pricinple it's possible to prepend a module to a singleton class. Let's see
  // if we need that in the future. As far as I know it's not possible to type this with RBS anyway.
  for(auto i = 0; i < rb_array_len(singleton_class_ancestors); ++i) {
    auto ancestor = singleton_class_ancestors_pointer[i];

    if(ancestor == singleton_class) {
      continue;
    }

    if(ancestor == object_singleton_class || ancestor == rb_cModule) {
      break;
    }

    if(RB_TYPE_P(ancestor, T_MODULE)) {
      // Constant is a module
      if(inner_constants.find(ancestor) == inner_constants.end()) {
        auto ancestor_constant = explore_constant(ancestor, &inner_constants);
        if(visited_constants) visited_constants->emplace(ancestor);

        constant->extended_modules.push_back(ancestor_constant->name);
      }
    }
  }

  if(visited_constants) {
    for(auto elem : inner_constants) {
      visited_constants->emplace(elem);
    }
  }

  auto result = constant_map.emplace(ruby_constant, constant);

  if(result.second) {
    constant_updates.push_back(ruby_constant);
  }

  return constant;
}

static ConstantInstance
class_to_constant_instance(VALUE klass, unsigned char generic_argument_count = 0, std::vector<ConstantInstance>* generic_arguments = nullptr) {
  auto existing_constant = constant_map.find(klass);
  std::shared_ptr<Constant> constant;
  if(existing_constant == constant_map.end()) {
    auto class_name = rb_mod_name(klass);
    if(!RB_NIL_P(class_name)) {
      auto current_space = rb_cObject;
      auto class_name_str = strdup(StringValueCStr(class_name));
      long constant_path_size = 0;
      char* occurence = nullptr;
      do {
        occurence = strstr(class_name_str, "::");

        if(!occurence) break;

        occurence[0] = '\0';
        current_space = rb_const_get_at(current_space, rb_intern(class_name_str));
        explore_constant(current_space);

        class_name_str = occurence + 2;
      } while(occurence != nullptr);
    }

    constant = explore_constant(klass);
  } else {
    constant = (*existing_constant).second;
  }


  return { constant->name, generic_argument_count, generic_arguments };
}

static int
hash_to_keys_and_values(VALUE key, VALUE value, VALUE ary) {
  rb_ary_push(ary, key);
  rb_ary_push(ary, value);
  return ST_CONTINUE;
}

std::pair<unsigned char, std::vector<ConstantInstance>*>
generic_arguments_by_value(VALUE value, VALUE klass, int depth = 0) {
  if(depth == maxGenericDepth) return { 0, nullptr };

  if (klass == rb_cArray) {
    auto length = rb_array_len(value);
    if(length > 0) {
      // We need to use a set and a vector to preserve order of the union types
      std::unordered_set<VALUE> types = {};
      std::vector<ConstantInstance> types_vec = {};
      auto ary_ptr = RARRAY_CONST_PTR(value);
      // This is O(n) and thus could be pretty slow
      for(auto j = 0; j < rb_array_len(value); ++j) {
        auto item = ary_ptr[j];

        auto klass = rb_class_of(item);
        auto generic_arguments = generic_arguments_by_value(item, klass, depth + 1);
        if(generic_arguments.first == 0) {
          auto result = types.insert(klass);
          if(result.second) {
            types_vec.push_back(class_to_constant_instance(klass));
          }
        } else {
          types_vec.push_back(class_to_constant_instance(klass, generic_arguments.first, generic_arguments.second));
        }
      }

      auto generic_arguments = new std::vector<ConstantInstance>[1];
      generic_arguments[0] = types_vec;
      return { 1, generic_arguments };
    }
  } else
  if(klass == rb_cHash) {
    // RACER-TODO: I think we can optimize this, if the parameter is a keyword argument rest because
    // keys of those must be symbols, right?
    auto hash_size = RHASH_SIZE(value);
    if(hash_size > 0) {

      std::unordered_set<VALUE> key_types = {};
      std::vector<ConstantInstance> key_vec = {};
      std::unordered_set<VALUE> value_types = {};
      std::vector<ConstantInstance> value_vec = {};

      VALUE keys_and_values = rb_ary_new_capa(hash_size * 2);
      rb_hash_foreach(value, hash_to_keys_and_values, keys_and_values);
      auto ary_ptr = RARRAY_CONST_PTR(keys_and_values);

      // This is O(2n) and thus could be pretty slow
      for(auto j = 0; j < hash_size; ++j) {
        auto key = ary_ptr[j * 2];
        auto key_type = rb_class_of(key);
        auto key_generics = generic_arguments_by_value(key, key_type, depth + 1);
        if(key_generics.first == 0) {
          auto key_result = key_types.insert(key_type);
          if(key_result.second) {
            key_vec.push_back(class_to_constant_instance(key_type));
          }
        } else {
          key_vec.push_back(class_to_constant_instance(key_type, key_generics.first, key_generics.second));
        }


        auto value = ary_ptr[j * 2 + 1];
        auto value_type = rb_class_of(value);
        auto value_generics = generic_arguments_by_value(value, value_type, depth + 1);
        if(value_generics.first == 0) {
          auto value_result = value_types.insert(value_type);
          if(value_result.second) {
            value_vec.push_back(class_to_constant_instance(value_type));
          }
        } else {
          value_vec.push_back(class_to_constant_instance(value_type, value_generics.first, value_generics.second));
        }
      }

      auto generic_arguments = new std::vector<ConstantInstance>[2];
      generic_arguments[0] = key_vec;
      generic_arguments[1] = value_vec;

      return { 2, generic_arguments };
    }
  }

  return { 0, nullptr };
}


static bool
process_event_check_path(VALUE path)
{
  auto range = RSTRING_LEN(path);

  struct reg_onig_search_args args = {
      .pos = 0,
      .range = range,
  };

  if(rb_reg_onig_match(pathMatcher, path, reg_onig_search, &args, NULL) == ONIG_MISMATCH) {
    return false;
  }

  return true;
}

static bool
should_process_event(rb_trace_arg_t *trace_arg)
{
  if(RB_NIL_P(pathMatcher)) {
    return true;
  }

  auto path = rb_tracearg_path(trace_arg);
  if(process_event_check_path(path)) {
    return true;
  }

  auto caller_locations = rb_funcall(rb_mKernel, callerLocationsId, 2, RB_INT2FIX(1), RB_INT2FIX(1));
  auto caller_location_length = rb_array_len(caller_locations);
  if(caller_location_length == 0) {
    return true;
  }

  auto caller_location = rb_ary_entry(caller_locations, 0);
  path = rb_funcall(caller_location, pathId, 0);
  if(process_event_check_path(path)) {
    return true;
  }

  return false;

}

static void process_block_call_event(rb_trace_arg_t*, ReturnTrace*);
static void process_block_return_event(rb_trace_arg_t*, ReturnTrace*);

static void
process_block_tracepoint(VALUE trace_point, void *data)
{
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point);
  auto *trace = (ReturnTrace*) data;

  switch(rb_tracearg_event_flag(trace_arg)) {
  case RUBY_EVENT_B_CALL:
    process_block_call_event(trace_arg, trace);
    break;
  case RUBY_EVENT_B_RETURN:
    process_block_return_event(trace_arg, trace);
    break;
  }
}

// Setting the target of the tracepoint may raise if the target's ISeq cannot be determined.
// This might happen if the proc object was defined using C (for example in Ruby core).
static VALUE
set_tracepoint_target_which_may_raise(VALUE hash) {
  auto tp = rb_hash_delete(hash, rb_id2sym(rb_intern("tp")));
  rb_funcallv_kw(tp, rb_intern("enable"), 1, &hash, RB_PASS_KEYWORDS);
  return Qtrue;
}

static void
assign_parameters(ReturnTrace* trace, rb_trace_arg_t* trace_arg) {
  VALUE parameters = rb_tracearg_parameters(trace_arg); // We may be able to cache this for each method? or access the parsed stuff idk
  auto total_params_size = rb_array_len(parameters);
  trace->params_size = 0;
  // Array of parameters objects. The array might be larger than the number of parameters we emit.
  trace->params = new Parameter[total_params_size];
  VALUE binding = rb_tracearg_binding(trace_arg);

  bool has_block = false;

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

      if(param_type == blockParam) {
        BlockParameter block_param = {};
        if(param_name_id != anonBlock) {
          block_param.name = param_name;
          auto block = rb_funcall(binding, rb_intern("local_variable_get"), 1, name);

          if(!RB_NIL_P(block)) {
            auto inspect = rb_inspect(block);
            auto tp = rb_tracepoint_new(Qnil, RUBY_EVENT_B_CALL | RUBY_EVENT_B_RETURN, process_block_tracepoint, trace);
            auto hash = rb_hash_new_capa(2);
            rb_hash_aset(hash, rb_id2sym(rb_intern("tp")), tp);
            rb_hash_aset(hash, rb_id2sym(rb_intern("target")), block);
            auto result = ::rb_rescue2(set_tracepoint_target_which_may_raise, hash, nullptr, 0, rb_eArgError, (VALUE) 0);
            if(result) {
              block_param.tracepoint_id = tp;
            }
          }
        }

        trace->block_param = block_param;

        has_block = true;
        continue;
      }

      unsigned char generic_argument_size = 0;
      std::vector<ConstantInstance>* generic_arguments = nullptr;

      if(param_name_id == anonRest) {
        param_class = rb_cArray;
      } else
      if(param_name_id == anonKeyrest) {
        param_class = rb_cHash;
      } else {
        VALUE value = rb_funcall(binding, rb_intern("local_variable_get"), 1, name);
        param_class = rb_class_of(value);

        auto generics = generic_arguments_by_value(value, param_class);
        generic_argument_size = generics.first;
        generic_arguments = generics.second;
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
      } else {
        rb_warn("Unknown parameter type %s\n", rb_id2name(param_type));
        continue;
      }

      trace->params[trace->params_size] = { param_name, class_to_constant_instance(param_class, generic_argument_size, generic_arguments), type };
      trace->params_size++;
    } else {
      if(param_type == nokeyParam) {
        // noKey means **nil which cannot be typed with RBS i think, so we ignore it for now
        continue;
      }

      if(param_type == reqParam) {
        trace->params[trace->params_size] = { nullptr, class_to_constant_instance(rb_cArray), REQUIRED };
        trace->params_size++;
        continue;
      }

      auto inspected_params = rb_inspect(parameters);
      rb_warn("Unexpected: Parameter has no name for method %s, parameters: %s", trace->method_name, StringValueCStr(inspected_params));
    }
  }

  if(!has_block) {
    if(rb_funcall(binding, rb_intern("block_given?"), 0) == Qtrue) {
      trace->block_param = BlockParameter { };
    }
  }
}

static void
process_call_event(rb_trace_arg_t *trace_arg)
{
  ReturnTrace *trace = new ReturnTrace;
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
    } else {
      // TODO: Check if these cases can still happen or if we can safe the check before
    }
  }

  // If the method isn't defined in self (say in a module or superclass) we want to add it to self instead.
  // This is a decision that might be revised. It's optimized for call site devexp but is bad for the callee.
  auto self = rb_tracearg_self(trace_arg);
  auto self_type = rb_type(self);
  if(self_type ==  T_CLASS || self_type == T_MODULE) {
    trace->method_kind = SINGLETON;
  } else {
    trace->method_kind = INSTANCE;
    self = rb_obj_class(self);
  }

  if(self != defined_class) {
    explore_constant(self);
  }

  trace->method_owner = class_to_constant_instance(defined_class);

  long fiber_id = rb_fiber_current();
  auto stack_pair = call_stacks.find(fiber_id);
  if(stack_pair != call_stacks.end()) {
    auto stack = (*stack_pair).second;
    if(!stack.empty()) {
      auto previous_trace = (*stack_pair).second.back();
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

  assign_parameters(trace, trace_arg);

  if(stack_pair == call_stacks.end()) {
    // TODO-Racer: Might want to increase initial capacity
    auto stack = std::vector<ReturnTrace*>();
    stack.push_back(trace);
    // fprintf(stderr, "[%ld] inserting method %s#%s\n", fiber_id, trace->method_owner_name, trace->method_name);
    call_stacks.insert({ fiber_id, stack });
  } else {
    // fprintf(stderr, "[%ld] pushing method %s#%s\n", fiber_id, trace->method_owner_name, trace->method_name);
    auto& stack = (*stack_pair).second;
    stack.push_back(trace);
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
    return;
  }

  auto& stack = (*stack_pair).second;

  if(stack.empty()) {
    // This might happen if the method call that returns now activated our tracepoint
    rb_warn("[%ld] Unexpected: Call stack empty for method %s\n", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
    return;
  }

  auto* trace = stack.back();
  if(!trace) {
    rb_warn("[%ld] Unexpected: Trace is null for method: %s", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
    return;
  }

  if(!trace->method_name) {
    rb_warn("Trying to return from method %s while a block is still on the stack", rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
  }

  if(strcmp(trace->method_name, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg)))) != 0) {
    // This could happen if we return from a function for which we do not have a call recorded
    // def foo -> not recorded
    //   Racer.start
    // end -> recorded but no call stack entry
    rb_warn("[%ld] Return: Method mismatch, expected %s, got %s", fiber_id, trace->method_name, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
    return;
  }

  stack.pop_back();
  //fprintf(stderr, "[%ld] popped method %s#%s\n", fiber_id, trace->method_owner_name, trace->method_name);

  auto return_value = rb_tracearg_return_value(trace_arg);
  auto return_value_class = rb_class_of(return_value);
  auto generics = generic_arguments_by_value(return_value, return_value_class);
  trace->return_type = class_to_constant_instance(return_value_class, generics.first, generics.second);

  if(trace->block_param.has_value()) {
    VALUE tracepoint_id = trace->block_param.value().tracepoint_id;
    if(tracepoint_id) {
      rb_tracepoint_disable(tracepoint_id);
    }
  }

  for(auto constant : constant_updates) {
    trace->constant_updates.push_back(constant_map.at(constant));
  }
  constant_updates.clear();

  tiny_queue_message_t *message = (tiny_queue_message_t *)malloc(sizeof(tiny_queue_message_t));
  message->queue_state = 1;
  message->data = trace;
  tiny_queue_push(tiny_queue, message);
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

    auto trace = stack.back();

    if(!trace) {
      rb_warn("[%ld] Unexpected: Trace is null for method: %s", fiber_id, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg))));
      return;
    }

    if(!trace->method_name || strcmp(trace->method_name, rb_id2name(SYM2ID(rb_tracearg_method_id(trace_arg)))) != 0) {
      // If these do not match the rescue happens inside a block and not inside the method. The method is not being retried in this case so we ignore this event.
      return;
    }

    // auto exception = rb_inspect(rb_tracearg_raised_exception(trace_arg));
    //fprintf(stderr, "[%ld] setting rescued to true for method %s#%s, exception: %s\n", fiber_id, trace->method_name, trace->method_owner_name, StringValueCStr(exception));
    trace->rescued = true;
  }
}

static void
process_block_call_event(rb_trace_arg_t* trace_arg, ReturnTrace* last_trace) {
  if(!last_trace->block_param.has_value()) {
    return;
  }

  auto& block_param = *(last_trace->block_param);
  ReturnTrace *trace = nullptr;
  if(block_param.current_block_call_stack.empty()) {
    trace = new ReturnTrace;

    // Note: we do not need to track rescued state for blocks as the :b_call event is only
    // executed once even if the block is being retried
    trace->rescued = false;

    assign_parameters(trace, trace_arg);

    auto self = rb_tracearg_self(trace_arg);
    auto self_type = rb_type(self);
    if(self_type == T_CLASS || self_type == T_MODULE) {
      auto constant_instance = class_to_constant_instance(self);
      constant_instance.singleton = true;
      trace->block_self_type = constant_instance;
    } else {
      auto self_class = rb_obj_class(self);
      auto generics = generic_arguments_by_value(self, self_class);
      trace->block_self_type = class_to_constant_instance(self_class, generics.first, generics.second);
    }
  }

  block_param.current_block_call_stack.push_back(trace);
}

static void
process_block_return_event(rb_trace_arg_t* trace_arg, ReturnTrace* last_trace) {
  if(!last_trace->block_param.has_value()) {
    rb_warn("Block return for method without block param (%s)", last_trace->method_name);
    return;
  }

  auto &block_param = last_trace->block_param.value();
  if (block_param.current_block_call_stack.empty()) {
    rb_warn("Current block call stack for method %s is empty.", last_trace->method_name);
    return;
  }
  auto last_block_call = block_param.current_block_call_stack.back();
  block_param.current_block_call_stack.pop_back();

  if(!last_block_call) {
    /*
    * This is a inner block call (so a block call inside a block of our method call)
    * For example
    * foo do <- actual block call, ReturnTrace on stack
    *   ->().call <- inner block call, added nullptr to stack
    * end
    */

    return;
  }

  auto return_value = rb_tracearg_return_value(trace_arg);
  auto return_value_class = rb_class_of(return_value);
  auto generics = generic_arguments_by_value(return_value, return_value_class);
  last_block_call->return_type = class_to_constant_instance(return_value_class, generics.first, generics.second);
  block_param.block_traces.push_back(last_block_call);
}

static void
process_tracepoint(VALUE trace_point, void *data)
{
  rb_trace_arg_t *trace_arg = rb_tracearg_from_tracepoint(trace_point);

  if(!should_process_event(trace_arg)) {
    return;
  }

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

static VALUE start(VALUE self, VALUE arg_pathMatcher, VALUE arg_maxGenericDepth)
{
  if(!RB_NIL_P(arg_pathMatcher)) {
    Check_Type(arg_pathMatcher, T_REGEXP);
  }
  pathMatcher = arg_pathMatcher;

  Check_Type(arg_maxGenericDepth, T_FIXNUM);
  maxGenericDepth = rb_fix2long(arg_maxGenericDepth);

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
      auto* trace = stack.back();
      stack.pop_back();
      if(!trace) continue;

      // TODO: Implement free_trace or deconstructor? (free method owner)
      if(trace->method_name) free(trace->method_name);
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
  method_defined = rb_intern("method_defined?");
  public_method_defined = rb_intern("public_method_defined?");
  private_method_defined = rb_intern("private_method_defined?");
  callerLocationsId = rb_intern("caller_locations");
  pathId = rb_intern("path");
  rb_global_variable(&tpCall);
  rb_global_variable(&pathMatcher);

  rb_define_singleton_method(Racer, "__c_start", start, 2);
  rb_define_singleton_method(Racer, "stop", stop, 0);
  rb_define_singleton_method(Racer, "flush", flush, 0);
}
