#!/usr/bin/env bash
# Why is ERMIA so slow on TPC-C (97% aborts even at W=96)? 2026-11-10.
cd "$(dirname "$0")"
B=/home/ubuntu/ccbench-adaTAM/build_release/cc/ermia/tpcc_ermia.exe
COMMON="--tpcc_num_wh=96 --tpcc_num_items=100000 --tpcc_home_warehouse_assignment=random_per_transaction --tpcc_home_warehouse_seed=1 --tpcc_balanced_home_prefix=true --tpcc_perc_payment=43 --tpcc_perc_order_status=4 --tpcc_perc_delivery=4 --tpcc_perc_stock_level=4 --tpcc_hot_item_ratio=0 --tpcc_hot_transaction_mode=false --tpcc_interactive_ms=0 --tpcc_retry_same_type=true --tpcc_log_retry_conflicts=false --clocks_per_us=2900 --tpcc_pin_order=physical_first --batch_th_num=0"
GC="--gc_inter_us=1000000000 --gc_defer_record_reclamation=false"
mkdir -p logs; echo "name,W,threads,extime,tps,abort_rate" > results.csv
run(){ name=$1; w=$2; th=$3; ex=$4; shift 4
  timeout 120 $B $COMMON --tpcc_active_warehouse_count=$w --thread_num=$th --extime=$ex "$@" > logs/$name.log 2>&1
  tps=$(grep -m1 "^throughput\[tps\]" logs/$name.log | awk '{print $NF}'); ab=$(grep -m1 "^abort_rate:" logs/$name.log | awk '{print $NF}')
  echo "$name,$w,$th,$ex,$tps,$ab" | tee -a results.csv; }
run cur_w96_10s   96 96 10 $GC --backoff_adaptive_exponential=true
run cur_w96_3s    96 96 3  $GC --backoff_adaptive_exponential=true
run nodbl_w96     96 96 10 $GC
run cur_w96_t48   96 48 10 $GC --backoff_adaptive_exponential=true
run cur_w96_t24   96 24 10 $GC --backoff_adaptive_exponential=true
run cur_w96_t8    96 8  10 $GC --backoff_adaptive_exponential=true
run cur_w96_t1    96 1  10 $GC --backoff_adaptive_exponential=true
run gcdefault_w96 96 96 10 --backoff_adaptive_exponential=true
run cur_w1_10s    1  96 10 $GC --backoff_adaptive_exponential=true
run cur_w1_t8     1  8  10 $GC --backoff_adaptive_exponential=true
