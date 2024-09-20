
#ifndef TRACES_H
#define TRACES_H 1

typedef struct ReturnTrace
{
  char *callee_id;
  char *callee_path;
  long callee_lineno;
  char *method_id;
  char *method_path;
  long method_lineno;
  char *return_type;
  // Params is an array where each even element is a parameter name
  // and the next element is the param type
  long params_size;
  char **params;
} ReturnTrace;

#endif /* TRACES_H */
