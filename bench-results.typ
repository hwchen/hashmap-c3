#import "lib/lilaq/src/lilaq.typ" as lq

= Bench Results

Run on chenbot, AMD ryzen

== Insert few integers

Insert integers from 100,000 to 5,000,000; every 200,000

// in seconds
#let xs = (
    0100000,
    0600000,
    1100000,
    1600000,
    2100000,
    2600000,
    3100000,
    3600000,
    4100000,
    4600000,
    5100000,
)
#let new_ys = (
    0.004,
    0.033,
    0.068,
    0.085,
    0.146,
    0.168,
    0.193,
    0.297,
    0.323,
    0.352,
    0.378,
)
#let std_ys = (
    0.013,
    0.122,
    0.283,
    0.454,
    0.535,
    0.646,
    0.752,
    0.977,
    1.122,
    1.182,
    1.294,
)
#let odin_ys = (
    0.018,
    0.118,
    0.228,
    0.570,
    0.650,
    0.735,
    0.848,
    1.362,
    1.429,
    1.530,
    1.627,
)
#let zig_ys = (
    0.003,
    0.029,
    0.061,
    0.076,
    0.128,
    0.145,
    0.174,
    0.265,
    0.284,
    0.319,
    0.348,
)

#lq.diagram(
  lq.plot(xs, new_ys),
  lq.plot(xs, std_ys),
  lq.plot(xs, odin_ys),
  lq.plot(xs, zig_ys),
  xlabel: "integers inserted",
  ylabel: "seconds",
)

== Insert many integers

Insert integers from 1,000 to 1,000,000,000 

- 18GB for 1 billion on chenbot
- 56.7G on chenbot for 1 billion was not enough, OOM killed


// in seconds
#let big_xs = (
    1000,
    10*1000,
    100*1000,
    1000*1000,
    10*1000*1000,
    100*1000*1000,
    //1000*1000*1000,
)
#let big_new_ys = (
    0.000077,
    0.000712,
    0.004,
    0.067,
    0.864,
    11.735,
    //(2*60) + 20441,
)
#let big_std_ys = (
    0.000077,
    0.000966,
    0.012,
    0.263,
    2.602,
    32.455,
    // OOM,
)
#let big_odin_ys = (
    0.000217,
    0.001955,
    0.017696,
    0.266,
    3.667,
    151.497,
    // OOM,
)
#let big_zig_ys = (
    0,
    0,
    0.003,
    0.055,
    0.829,
    12.291,
    //1000*1000*1000,
)

#lq.diagram(
  lq.plot(big_xs, big_new_ys),
  lq.plot(big_xs, big_std_ys),
  lq.plot(big_xs, big_odin_ys),
  lq.plot(big_xs, big_zig_ys),
  xscale: "log",
  //yscale: "log",
  xlabel: "integers inserted",
  ylabel: "seconds",
)
