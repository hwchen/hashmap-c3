#import "lib/lilaq/src/lilaq.typ" as lq

= Bench Results

Benchmark follows

// in milliseconds
#let xs = (0,100*1000,1000*1000,10*1000*1000,100*1000*1000)
#let std_ys = (0,6,96,1137,14892)
#let new_ys = (0,29,388,4488,0)

#lq.diagram(
  lq.plot(xs, std_ys),
  lq.plot(xs, new_ys),
)
