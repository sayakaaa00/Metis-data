# Metis-data: measured results of the Metis paper

This repository holds the raw measurements (per-run logs and result CSVs)
behind the figures and numbers of the Metis paper. The code, the experiment
scripts, and the figure scripts are in
[sayakaaa00/ccbench-Metis](https://github.com/sayakaaa00/ccbench-Metis), which
includes this repository as the submodule `data/`.

Only the runs that the paper's figures and numbers use are included. Files are
copied unchanged from the working directory in which they were measured. Result
CSVs are filtered by row (the header and the values are unchanged). `MANIFEST.tsv` lists the original path of every directory and file.

## Machine

AWS, 2 × Intel Xeon Platinum 8375C (48 physical cores, 96 logical CPUs, 2 NUMA
nodes), 185 GiB of memory, Ubuntu 24.04, GCC 13. Every run starts 96 worker
threads, one per logical CPU, pinned physical-core first (socket 0, socket 1,
then the SMT siblings). TSC: 2900 clocks per µs.

## Workloads

- **TPC-C**: standard mix on 96 warehouses. The home warehouse is drawn from the first
  `W` warehouses (`W` = 1, 2, 3, 4, 8, 16, 32, 96). Runs last 30 s, and the control period is 200 ms.
- **YCSB**: 10,000 records, 10 operations per transaction, 50 % reads, Zipf
  skew 0 to 0.999. Runs last 10 s, and the control period is 10 ms.
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
| `metis_v2`, `metis` | Metis |
| `metis_v2_norephys` | Metis without re-measuring the physical-core count (`--metis_v2_recheck_physical=false`), used for `Y4` |
| `adatam` | Hill climbing on the active thread count (step 8 for TPC-C, 4 for YCSB) |
| `silo_cbo_tuned` | Silo-BO: Silo with the adaptive backoff of Cicada, tuned (see `*/backoff_adaptive_tuning`) |
| `silo_nobo` | Silo (all worker threads, no backoff) |
| `cicada`, `ermia` | Cicada and ERMIA with adaptive backoff |
| oracle | Silo with the best fixed active thread count (`*/oracle`) |

The flags in `config.txt` and the logs use the names from the time of measurement
(`--metis_v2_*`, `--linucb_model_path`). In ccbench-Metis these are
`--metis_*` and `--metis_model_path`.

## Training and models (`min8`, `min6`)

Metis chooses among the even active thread counts. Two sets of training runs exist:

- `*/train/min8`, `*/models/min8`: candidates 8 to 96. These models were used for the Metis runs in
  `tpcc/fixed`, `ycsb/fixed/results_metis.csv`, `tpcc/dynamic`, and `ycsb/dynamic`.
- `*/train/min6`, `*/models/min6`: candidates 6 to 96, retrained on 2026-11-08. These models were used for
  `tpcc/dynamic_hill_climbing` (`models/min6/all.txt`).
- `ycsb/models/min6_lowskew`: `min6` training runs including skew 0 and 0.5. These models were used for
  `ycsb/fixed/skew_0-0.5_metis`, `ycsb/fixed/skew_0.7-0.999_metis` (leave-one-out),
  and `ycsb/dynamic_hill_climbing` (`all_with_low.txt`).

`train/*/state_<s>_run<r>.txt` holds the statistics of one training run. A model file is the sum of
these statistics over the training runs. `loo_<s>.txt` leaves state `<s>` out, and the fixed-load runs of
state `<s>` use it.

## Layout and paper figures

| Directory | Contents | Used for |
|---|---|---|
| `ycsb/oracle/skew_0.7-0.999`, `ycsb/oracle/skew_0-0.5` | Throughput of every fixed active thread count (2 runs × 10 s) | Throughput vs. active thread count (Intro, Background), oracle in all YCSB figures |
| `tpcc/oracle` | The same for TPC-C (`w<W>/results.csv`, `oracle_summary.json`) | Throughput vs. active thread count (Background), oracle in all TPC-C figures |
| `ycsb/breakdown` | Share of worker time on committed / aborted transactions vs. skew | Breakdown figure (Intro), abort rate in Background |
| `ycsb/backoff_constant`, `tpcc/backoff_constant` | Silo with a fixed backoff duration (sweep) | Backoff sensitivity (Background), best fixed backoff (Evaluation: thread throttling vs. backoff) |
| `ycsb/backoff_exponential` | Silo with exponential backoff, sweep of the initial duration | Background ("up to 86 % lower") |
| `*/backoff_adaptive_tuning` | Silo-BO for 4 update periods × 4 step sizes (`sweep.csv`) | Choice of the Silo-BO setting, Background ("up to 48 % lower") |
| `*/fixed` | Fixed load: Silo, Silo-BO, Cicada, ERMIA, hill climbing (`results.csv`), Metis (`results_metis.csv`) | Static evaluation figures, hill-climbing comparison |
| `ycsb/fixed/skew_0-0.5_*`, `ycsb/fixed/skew_0.7-0.999_metis` | YCSB at low skew (baselines and Metis), and Metis at high skew with the low-skew-trained models | Static evaluation (YCSB) |
| `ycsb/fixed/hill_climbing_10ms_log` | Hill climbing on YCSB with a log entry every control period | Active thread count / throughput over the first 150 control periods |
| `tpcc/fixed/ermia_3s` | ERMIA on TPC-C | Static evaluation (TPC-C, ERMIA) |
| `*/dynamic` | `D1`, `Y1`: Metis, Silo-BO, Silo, Cicada, ERMIA | Throughput over time on dynamic workloads |
| `*/dynamic_hill_climbing` | `D11`, `Y4`: Metis and hill climbing | Active thread count on dynamic workloads (hill-climbing comparison) |
| `*/train`, `*/models` | Training runs and models | Every Metis run |

## File formats

- `results.csv`: one row per run. Throughput (`tps`, committed transactions per second) and abort rate
  are averaged over the whole run.
- `*.log`: standard output of the benchmark (flags and final statistics). `*.trace.log`: controller log,
  with one `[MetisV2]` (Metis) or `[AdaTAM]` (hill climbing) line per decision, `[TAM sample]` lines
  (active thread count at time `bench_s`), and in some runs `[TPS sample]` lines. `[TAM sample]` is written every 100 ms by default,
  every 200 ms in the TPC-C runs, and every 10 ms in `ycsb/fixed/hill_climbing_10ms_log` and `ycsb/dynamic_hill_climbing`.
- Oracle and some other directories have a `config.txt` with the binary path, its SHA-256, and the git
  commit of the code at the time of measurement.
- `config.txt`: the command line and settings of the experiment script.

The MySQL experiments are in
[Tatzhiro/MySQL-Metis-experiments](https://github.com/Tatzhiro/MySQL-Metis-experiments).
