set shell := ["bash", "-uc"]

# can inspect results with `perf report`
# sudo sysctl kernel.perf_event_paranoid=1
perf bin *args="":
    perf record --call-graph dwarf {{bin}} {{args}} > /dev/null

# stackcollapse-perf.pl and flamegraph.pl symlinked into path from flamegraph repo
flamegraph:
    perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg
