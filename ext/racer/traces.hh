
#ifndef TRACES_H
#define TRACES_H 1

typedef struct ReturnTrace
{
  const char *method_owner_name;
  const char *method_owner_type;
  const char *method_name;
  // Params is an array where each even element is a parameter name
  // and the next element is the param type
  long params_size;
  char **params;
} ReturnTrace;

#endif /* TRACES_H */
