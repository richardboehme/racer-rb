
#ifndef TRACES_H
#define TRACES_H 1

enum ParamType {
  REQUIRED = 0,
  OPTIONAL = 1,
  REST = 2,
  KEYWORD_REQUIRED = 3,
  KEYWORD_OPTIONAL = 4,
  KEYWORD_REST = 5,
  BLOCK = 6
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

typedef struct Path {
  char* name { nullptr };
  ClassType type { MODULE };
} Path;

typedef struct GenericArgument GenericArgument;

typedef struct Constant {
  char* name { nullptr };
  ClassType type { MODULE };
  long path_size { 0 };
  Path* path { nullptr };
  unsigned char generic_argument_count { 0 };
  GenericArgument* generic_arguments { nullptr };
} Constant;

struct GenericArgument {
  unsigned long union_size { 0 };
  Constant* union_types { nullptr };
};

typedef struct Parameter {
  char* name { nullptr };
  Constant type_name {};
  ParamType param_type { REQUIRED };
} Parameter;

typedef struct ReturnTrace
{
  Constant method_owner {};
  char *method_name { nullptr };
  MethodKind method_kind { INSTANCE };
  MethodVisibility method_visibility { PUBLIC };
  Constant return_type {};
  // Params is an array where each even element is a parameter name
  // and the next element is the param type
  long params_size { 0 };
  Parameter *params { nullptr };
  bool rescued { false };
} ReturnTrace;

#endif /* TRACES_H */
