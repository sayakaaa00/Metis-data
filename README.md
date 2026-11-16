# Metis-data: measured results of the Metis paper

This repository holds the raw measurements (per-run logs and result CSVs)
behind the figures and numbers of the Metis paper. The code, the experiment
scripts, and the figure scripts are in
[sayakaaa00/ccbench-Metis](https://github.com/sayakaaa00/ccbench-Metis), which
includes this repository as the submodule `data/`.
`experiments/metis/figures/make_figures.sh` regenerates every figure of the
paper from this repository, and the output matches the paper's figures pixel for pixel. The experiment
scripts in `experiments/metis/` write new runs in the same layout.

Only the runs that the paper's figures and numbers use are included. Log files
are copied unchanged from the working directory in which they were measured;
some are renamed to a common pattern. Result CSVs are filtered or concatenated
by row (header and values unchanged). `MANIFEST.tsv` lists the origin of every
directory and file.

## Machine

AWS, 2 × Intel Xeon Platinum 8375C (48 physical cores, 96 logical CPUs, 2 NUMA
nodes), 185 GiB of memory, Ubuntu 24.04, GCC 13. Every run starts 96 worker
threads, one per logical CPU, pinned physical-core first (socket 0, socket 1,
then the SMT siblings). TSC: 2900 clocks per µs.

## Workloads

- **TPC-C**: standard mix on 96 warehouses. The home warehouse is drawn from the
  first `W` warehouses (`W` = 1, 2, 3, 4, 8, 16, 32, 96). Runs last 30 s, and the
  control period is 200 ms.
- **YCSB**: 10,000 records, 10 operations per transaction, 50 % reads, Zipf skew 0 to 0.999.
  Runs last 10 s, and the control period is 10 ms.
- **Dynamic workloads** (60 s, two changes):

  | Name | Benchmark | Change | Paper use |
  |---|---|---|---|
  | `D1` | TPC-C | `W` 16 → 1 (20 s) → 4 (40 s) | Throughput over time |
  | `Y1` | YCSB | skew 0.7 → 0.95 → 0.8 | Throughput over time |
  | `D11` | TPC-C | `W` 2 → 8 → 1 | Comparison with hill climbing |
  | `Y4` | YCSB | skew 0.99 → 0.5 → 0.95 | Comparison with hill climbing |

## Method names in files

| Name in files | Name in the paper |
|---|---|
| `metis_v2`, `metis_v2_lowtrained` | Metis |
| `metis_v2_norephys` | Metis without re-measuring the physical-core count (`--metis_recheck_physical=false`), used for `Y4` |
| `hill_climbing` | Hill climbing on the active thread count (step 8 for TPC-C, 4 for YCSB) |
| `silo_cbo_tuned` | Silo-BO: Silo with the adaptive backoff of Cicada, tuned (see `*/backoff_adaptive_tuning`) |
| `silo_nobo` | Silo (all worker threads, no backoff) |
| `cicada`, `ermia` | Cicada and ERMIA with adaptive backoff |
| oracle | Silo with the best fixed active thread count (`*/oracle`) |

The flags in the logs use the names from the time of measurement
(`--metis_v2_*`, `--linucb_model_path`); in ccbench-Metis these are `--metis_*`
and `--metis_model_path`. Runs of the current scripts write `metis` instead of `metis_v2`.
Hill-climbing runs are named `hill_climbing` in the CSVs and file names; the log contents and
flags keep the controller's name at measurement time.

## Training and models (`min8`, `min6`)

Metis chooses among even active thread counts. Two training sets exist:

- `*/train/min8`, `*/models/min8`: candidates 8 to 96. Used for Metis in
  `tpcc/fixed`, `tpcc/dynamic` (D1), and `ycsb/dynamic` (Y1).
- `*/train/min6`, `*/models/min6`: candidates 6 to 96. Used for Metis in `ycsb/fixed`,
  `tpcc/dynamic_hill_climbing` (D11), and `ycsb/dynamic_hill_climbing` (Y4).
  YCSB `min6` is trained on all nine skews (0 to 0.999).

`train/<set>/state_<s>_run<r>.txt` holds the ridge-regression statistics of one
30-s training run. A model sums them over runs. `all.txt` pools every level, and
`loo_<s>.txt` leaves level `<s>` out (the static runs of `<s>` use it). The
models in ccbench-Metis (`experiments/metis/models`) are these files with the
current header (`metis_model 1 ...` instead of `metis_v2_model 1 A 1 ...`).

## Layout

| Directory | Contents | Paper |
|---|---|---|
| `ycsb/oracle/skew_0.7-0.999` | Silo, throughput of every fixed active thread count (2 runs × 10 s) | Throughput vs. active thread count (Background), oracle |
| `ycsb/oracle/skew_0_0.5_0.9` | The same for skew 0, 0.5, and 0.9 | Introduction (skew 0 and 0.9), oracle at skew 0 and 0.5 |
| `tpcc/oracle/w<W>` | The same for TPC-C (coarse grid, then 2-step points around the best). `oracle_summary.json` equals the means of `w*/results.csv` | Background, oracle |
| `ycsb/breakdown` | Worker time on committed / aborted transactions and lock waiting vs. skew | Introduction, Background |
| `ycsb/backoff_constant`, `tpcc/backoff_constant` | Silo with a fixed backoff duration | Background (sensitivity), best fixed backoff (Evaluation) |
| `ycsb/backoff_exponential` | Silo with exponential backoff, initial duration swept | Background ("up to 86 % lower") |
| `*/backoff_adaptive_tuning` | Silo-BO for 4 update periods × 4 steps (`sweep.csv`) | Silo-BO setting, Background ("up to 48 % lower") |
| `*/fixed` | Static workloads: `results.csv` (Silo, Silo-BO, Cicada, ERMIA, hill climbing) and `results_metis.csv` | Static evaluation |
| `tpcc/fixed/ermia_3s` | ERMIA on TPC-C (3-s runs) | Static evaluation (TPC-C) |
| `ycsb/hill_climbing_10ms_log` | Hill climbing on YCSB with an active-thread sample every control period | Comparison with hill climbing (static) |
| `*/dynamic` | `D1` / `Y1`: Metis (`results_metis.csv`), Silo-BO, Silo, Cicada, ERMIA | Throughput over time |
| `*/dynamic_hill_climbing` | `D11` / `Y4`: Metis and hill climbing | Comparison with hill climbing (dynamic) |
| `*/train`, `*/models` | Training runs and models | Every Metis run |

Selected runs in the figures: run 1, except in the TPC-C D1 figure (Metis run 2) and in the YCSB Y1 figure (Cicada
run 2; run 1 stops committing at 38 s). Numbers in the text are means of the two runs unless stated otherwise.

## File formats

- `results.csv`: one row per run. Throughput (`tps`, committed transactions per second) and abort rate are averaged
  over the whole run. `mode_threads` / `mean_threads` summarize the active thread count of Metis and hill-climbing
  runs (empty for the other methods).
- `*.log`: standard output of the benchmark (flags and final statistics). `*.trace.log`: controller log, with one
  `[MetisV2]` (Metis) or hill-climbing line per decision (tagged with the controller's name at measurement time), `[TAM sample]` lines (active thread count at
  time `bench_s`), and in some runs `[TPS sample]` lines. `[TAM sample]` is written every 100 ms by default,
  every 200 ms in the TPC-C runs, and every 10 ms in `ycsb/hill_climbing_10ms_log` and
  `ycsb/dynamic_hill_climbing`. Cicada and ERMIA on TPC-C log `[TPC-C interval]` lines instead of `[TPS sample]`.
- `config.txt`: settings of the experiment script, and in some directories the binary path, its SHA-256, and
  the git commit of the code at the time of measurement.

The MySQL experiments are in
[Tatzhiro/MySQL-Metis-experiments](https://github.com/Tatzhiro/MySQL-Metis-experiments).
