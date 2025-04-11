$counter = 0
def foo
  if $counter == 0
    raise
  else
    $counter += 1
  end
rescue
  retry
end

foo

# Expect one call to foo
