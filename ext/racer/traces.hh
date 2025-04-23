
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

typedef struct Parameter {
  char* name = nullptr;
  char* class_name = nullptr;
  ParamType type;
} Parameter;

typedef struct Path {
  char* name;
  ClassType type;
} Path;

typedef struct TypeName {
  char* name;
  ClassType type;
  long namespace_size;
  Path* paths;
} TypeName;

typedef struct ReturnTrace
{
  TypeName method_owner;
  char *method_name;
  char *return_type;
  // Params is an array where each even element is a parameter name
  // and the next element is the param type
  long params_size;
  Parameter *params;
  bool rescued;
} ReturnTrace;

#endif /* TRACES_H */
