#ifndef RACER_H
#define RACER_H 1

#include "ruby.h"
#include "ruby/ruby.h"
#include "ruby/debug.h"
#include "ruby/re.h"
#include "pthread.h"
#include "worker.hh"
#include "tiny_queue.hh"
#include "traces.hh"

struct reg_onig_search_args {
  long pos;
  long range;
};

// Copied from ruby/re.c because the function is not exported in re.h
static OnigPosition
reg_onig_search(regex_t *reg, VALUE str, struct re_registers *regs, void *args_ptr)
{
    struct reg_onig_search_args *args = (struct reg_onig_search_args *)args_ptr;
    const char *ptr;
    long len;
    RSTRING_GETMEM(str, ptr, len);

    return onig_search(
        reg,
        (UChar *)ptr,
        (UChar *)(ptr + len),
        (UChar *)(ptr + args->pos),
        (UChar *)(ptr + args->range),
        regs,
        ONIG_OPTION_NONE);
}

#endif /* RACER_H */
