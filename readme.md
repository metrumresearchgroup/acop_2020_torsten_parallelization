- [Setup `cmdstan` runs](#orgdcf4228)
- [Cross-chain warmup benchmarks](#orgdb39bbd)
- [Multilevel example: TTPN model](#org853cedb)

This repo contains details of our ACoP11 poster "Speed up populational Bayesian inference by combining cross-chain warmup and within-chain parallelization"(Yi Zhang, William R. Gillespie, Ben Bales, Aki Vehtari). The `acop_2020_multilevel_parallel` branch of `cmdstan` directory points to the source code used in this study. It is implemented on top of existing Torsten within-chain parallel ODE group solvers and an experimental warmup algorithm. More discussions on the new warmup algorithm can be found at Stan discussion forum <https://discourse.mc-stan.org/t/new-adaptive-warmup-proposal-looking-for-feedback/12039> <https://discourse.mc-stan.org/t/cross-chain-warmup-adaptation-using-mpi/12912>


<a id="orgdcf4228"></a>

# Setup `cmdstan` runs

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

To build and run a model, say `cmdstan/examples/arK/arK.stan`, do

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


<a id="orgdb39bbd"></a>

# Cross-chain warmup benchmarks


<a id="org853cedb"></a>

# Multilevel example: TTPN model
