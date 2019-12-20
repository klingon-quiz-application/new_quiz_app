max = 5

a = (1 .. max).to_a.sort_by{rand}[0..3]
b = (0 .. 2).to_a.sort_by{rand}[0..2]
puts a
puts b
puts a[b[1]]