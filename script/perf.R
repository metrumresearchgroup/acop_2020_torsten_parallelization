library(dplyr)
library(rstan)

rm(list=ls())

cross.chain.runs <- paste0("cc_run_nproc_", c(4, 8, 16, 32, 60))
within.chain.runs <- paste0("run_nproc_",c(1, 2, 4, 8, 15),"_per_chain")
seq.run <- "seq_run"
all.runs <- c(cross.chain.runs, within.chain.runs)

max.total.time.fit <-
    function(stanfit){stanfit %>% rstan::get_elapsed_time(.) %>% as.data.frame() %>% 
                          mutate(total = warmup + sample) %>% filter(total == max(total))}
max.total.time <-
    function(path.name){rstan::read_stan_csv(dir(path=path.name,pattern="*.csv",full.name=TRUE)) %>% 
                            max.total.time.fit(.)}

regular.elapsed <- max.total.time(seq.run)
speedup <- lapply(c(cross.chain.runs, within.chain.runs),
                  FUN=max.total.time) %>% do.call(rbind.data.frame, .) %>% 
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
