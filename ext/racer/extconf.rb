require "mkmf"

$CXXFLAGS += " -std=c++17 "
$CXXFLAGS += " -ggdb3 -Og "

# Makes all symbols private by default to avoid unintended conflict
# with other gems. To explicitly export symbols you can use RUBY_FUNC_EXPORTED
# selectively, or entirely remove this flag.
append_cflags("-fvisibility=hidden")

have_library("pthread")
have_library("json-c")

create_makefile "racer"
