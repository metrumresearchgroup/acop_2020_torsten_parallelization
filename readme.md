- [Setup `cmdstan` and build models](#orgf7c3e43)
- [Cross-chain warmup benchmarks](#org8f0e356)
- [Multilevel example: TTPN model](#org2366c10)
  - [Multilevel runs](#org076a5ef)
  - [Within-chain parallel runs](#org581ea00)
  - [4 regular runs as 4 chains](#orgc9027a9)

This repo contains details of our ACoP11 poster "Speed up populational Bayesian inference by combining cross-chain warmup and within-chain parallelization"(Yi Zhang, William R. Gillespie, Ben Bales, Aki Vehtari). The `acop_2020_multilevel_parallel` branch of `cmdstan` directory points to the source code used in this study. It is implemented on top of existing Torsten within-chain parallel ODE group solvers and an experimental warmup algorithm. More discussions on the new warmup algorithm can be found at Stan discussion forum <https://discourse.mc-stan.org/t/new-adaptive-warmup-proposal-looking-for-feedback/12039> <https://discourse.mc-stan.org/t/cross-chain-warmup-adaptation-using-mpi/12912>


<a id="orgf7c3e43"></a>

# Setup `cmdstan` and build models

For regular runs, set `cmdstan/make/local`

```sh
STANC2=true
```

For within-chain parallel runs, set `cmdstan/make/local`

```sh
STANC2=true
TORSTEN_MPI=1
TBB_CXX_TYPE=clang              # or gcc
```

For multilevel(cross-chain warmup + within-chain) parallel runs, set `cmdstan/make/local`

```sh
STANC2=true
MPI_ADAPTED_WARMUP=1
TORSTEN_MPI=1
TBB_CXX_TYPE=clang              # or gcc
```

To build and run a model(we use `cmdstan/examples/arK/arK.stan` as example through out), do

```sh
cd cmdstan
make -j2 examples/arK/arK

cd examples/arK
# regular sequential run
./arK sample save_warmup=1 data file=arK.data.R
# parallel run
mpiexec -n nproc ./arK sample save_warmup=1 data file=arK.data.R
```

For more running options, use

```sh
./arK help-all
```

In particular, cross-chain warmup builds come with additional options

```sh
adapt num_cross_chains          # number of communicating chains, # default 4
adapt cross_chain_window        # warmup window, default 100
adapt cross_chain_rhat          # target Rhat, default 1.05
adapt cross_chain_ess           # target ESS, default 200
```

All models in this study are located in `cmdstan/examples/`.


<a id="org8f0e356"></a>

# Cross-chain warmup benchmarks

The following models from [posteriordb](https://github.com/MansMeg/posteriordb) are used for benchmark: arK, arK-arK, eight\_schools, garch-garch11, radon, sblrc-blr, SIR. `scripts/run_cc.R` contains some scripts used for parallel runs as well as summary generation. In particular, given a `stanfit` object, the performance summary can be obtained by

```r
source("scripts/run_cc.R")
perf.cc(stanfit)
```

With cross-chain build binary `arK` and regular build binary `arK_seq`,

```r
multiple.run.ess("examples", "arK", 4, 4, "hostfile", seq(8235121, 8235130), c(100,200,400))
```

performs MPI runs (`mpiexec -n 4`) using cross-chain as well as regular builds, with random seeds 8235121-8235130 and target ESS 100, 200, and 400, on machine(s) specified by `hostfile`.


<a id="org2366c10"></a>

# Multilevel example: TTPN model

Parallel speedup benchmark is based on 4-chain runs with total `nproc` processes on a `METWORX` *workflow*, so that `nproc/4` processes are assigned to each chain. All computing nodes are equipped with 2 vCPUs and 8 GB RAM. Each process occupies a single node(bind to socket). Note that in multilevel runs `np` in `mpiexec -n np` command designate the total number of processes for 4 chains, while in within-chain parallel runs it referes to the number of processes for a single chain. In reference regular runs, each chain is solved by a single processes.


<a id="org076a5ef"></a>

## Multilevel runs

```bash
# ttpn2_group is built with TORSTEN_MPI=1 and MPI_ADAPTED_WARMUP=1.
mpiexec -n nproc -l -f hostfile ./ttpn2_group sample adapt num_cross_chains=4 cross_chain_ess=400 data file=ttpn2.data.R init=init.R random seed=8325121
```


<a id="org581ea00"></a>

## Within-chain parallel runs

```bash
# ttpn2_group is built with TORSTEN_MPI=1.
mpiexec -n nproc -l -f hostfile ./ttpn2_group sample data file=ttpn2.data.R init=mpi.0.init.R random seed=8325121 id=0 output file=output.1.csv
mpiexec -n nproc -l -f hostfile ./ttpn2_group sample data file=ttpn2.data.R init=mpi.1.init.R random seed=8325121 id=1 output file=output.2.csv
mpiexec -n nproc -l -f hostfile ./ttpn2_group sample data file=ttpn2.data.R init=mpi.2.init.R random seed=8325121 id=2 output file=output.3.csv
mpiexec -n nproc -l -f hostfile ./ttpn2_group sample data file=ttpn2.data.R init=mpi.3.init.R random seed=8325121 id=3 output file=output.4.csv
```


<a id="orgc9027a9"></a>

## 4 regular runs as 4 chains

```bash
# ttpn2_group is built without TORSTEN_MPI=1 or MPI_ADAPTED_WARMUP=1
./ttpn2_group sample data file=ttpn2.data.R init=mpi.0.init.R random seed=8325121 id=0 output file=output.1.csv
./ttpn2_group sample data file=ttpn2.data.R init=mpi.1.init.R random seed=8325121 id=1 output file=output.2.csv
./ttpn2_group sample data file=ttpn2.data.R init=mpi.2.init.R random seed=8325121 id=2 output file=output.3.csv
./ttpn2_group sample data file=ttpn2.data.R init=mpi.3.init.R random seed=8325121 id=3 output file=output.4.csv
```

One can examine the `.RData` at root path of this repo for corresponding `stanfit` objects used for speedup study:

```bash
ttpn2.multilevel.nproc.60       # nproc = 60
ttpn2.multilevel.nproc.32       # nproc = 32
ttpn2.multilevel.nproc.16       # nproc = 16
ttpn2.multilevel.nproc.8        # nproc = 8
ttpn2.multilevel.nproc.4        # nproc = 4

ttpn2.within.chain.nproc.15     # nproc per chain = 15
ttpn2.within.chain.nproc.8      # nproc per chain = 8
ttpn2.within.chain.nproc.4      # nproc per chain = 4
ttpn2.within.chain.nproc.2      # nproc per chain = 2
ttpn2.within.chain.nproc.1      # nproc per chain = 1

ttpn2.seq                       # 4-chain regular runs
```

and generate speedup plot by

```r
library(dplyr)
library(rstan)

max.total.time.fit <-
    function(stanfit){stanfit %>% rstan::get_elapsed_time(.) %>% as.data.frame() %>% 
                          mutate(total = warmup + sample) %>% filter(total == max(total))}

regular.elapsed <- max.total.time.fit(ttpn2.seq)

all.runs <- c(ttpn2.multilevel.nproc.4, ttpn2.multilevel.nproc.8, ttpn2.multilevel.nproc.16, ttpn2.multilevel.nproc.32, ttpn2.multilevel.nproc.60, ttpn2.within.chain.nproc.1, ttpn2.within.chain.nproc.2, ttpn2.within.chain.nproc.4, ttpn2.within.chain.nproc.8, ttpn2.within.chain.nproc.15)
speedup <- lapply(all.runs, FUN=max.total.time) %>% do.call(rbind.data.frame, .) %>% 
    mutate(parallelisation=c("multilevel","multilevel","multilevel","multilevel","multilevel","within-chain","within-chain","within-chain","within-chain","within-chain")) %>% 
    mutate(nproc.per.chain=c(1,2,4,8,15,1,2,4,8,15)) %>%
    mutate(warmup.speedup = regular.elapsed$warmup / warmup) %>%
    mutate(sample.speedup = regular.elapsed$sample / sample) %>%
    mutate(total.speedup = regular.elapsed$total / total) %>%
    select(parallelisation, nproc.per.chain, warmup.speedup, sample.speedup, total.speedup) %>%
    rename(warmup = warmup.speedup, sample = sample.speedup, total = total.speedup)

speedup.long <- reshape2::melt(speedup, id = c("nproc.per.chain","parallelisation"),
                               measure = c("warmup", "sample", "total"),
                               value.name = "speedup")

ggplot(speedup.long, aes(x=nproc.per.chain, y=speedup, color=parallelisation)) +
    geom_line() + geom_point() +
    facet_wrap(~ variable,scales="free_y") + scale_y_log10(breaks=c(1,2,4,8)) +
    scale_x_log10(breaks=c(1,2,4,8,15)) +
    xlab("number of processes per chain") +
    theme(legend.position="bottom")
```
