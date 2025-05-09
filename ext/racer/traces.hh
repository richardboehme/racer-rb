
#ifndef TRACES_H
#define TRACES_H 1

#include <vector>
#include <optional>
#include <memory>

enum ParamType {
  REQUIRED = 0,
  OPTIONAL = 1,
  REST = 2,
  KEYWORD_REQUIRED = 3,
  KEYWORD_OPTIONAL = 4,
  KEYWORD_REST = 5
};

enum ClassType {
  MODULE = 0,
  CLASS = 1,
};

enum MethodKind {
  INSTANCE = 0,
  SINGLETON = 1,
};

enum MethodVisibility {
  PUBLIC = 0,
  PRIVATE = 1,
  PROTECTED = 2,
};

typedef struct Constant {
  char* name { nullptr };
  bool anonymous { false };
  ClassType type { MODULE };
  std::optional<char*> superclass {};
  std::vector<char*> included_modules {};
  std::vector<char*> prepended_modules {};
  std::vector<char*> extended_modules {};
} Constant;

typedef struct ConstantInstance {
  char* name { nullptr };
  unsigned char generic_argument_count { 0 };
  std::vector<ConstantInstance>* generic_arguments {};
  bool singleton { false };
} ConstantInstance;

typedef struct Parameter {
  char* name { nullptr };
  ConstantInstance type_name { 0 };
  ParamType param_type { REQUIRED };
} Parameter;

typedef struct ReturnTrace ReturnTrace;

typedef struct BlockParameter {
  char* name { nullptr };
  unsigned long tracepoint_id { 0 };
  std::vector<ReturnTrace*> block_traces {};
  std::vector<ReturnTrace*> current_block_call_stack {};
} BlockParameter;

struct ReturnTrace
{
  ConstantInstance method_owner {};
  char *method_name { nullptr };
  MethodKind method_kind { INSTANCE };
  MethodVisibility method_visibility { PUBLIC };
  ConstantInstance return_type {};
  long params_size { 0 };
  Parameter *params { nullptr };
  bool rescued { false };

  std::vector<std::shared_ptr<Constant>> constant_updates {};

  std::optional<BlockParameter> block_param {};
  // only relevant for block traces, maybe we could reuse the method_owner Constant but I think it would
  // be even better if we could split those two types anyway
  std::optional<ConstantInstance> block_self_type {};
};

#endif /* TRACES_H */
