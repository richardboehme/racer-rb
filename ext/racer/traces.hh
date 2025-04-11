
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

typedef struct Parameter {
  const char* name = nullptr;
  const char* class_name = nullptr;
  ParamType type;
} Parameter;

typedef struct ReturnTrace
{
  const char *method_owner_name;
  const char *method_owner_type;
  const char *method_name;
  const char *return_type;
  // Params is an array where each even element is a parameter name
  // and the next element is the param type
  long params_size;
  Parameter *params;
} ReturnTrace;

#endif /* TRACES_H */
