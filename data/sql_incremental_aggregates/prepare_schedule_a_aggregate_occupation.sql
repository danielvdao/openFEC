-- Drop the old functions if they still exist.
drop function if exists ofec_sched_a_update_aggregate_occupation();

-- Create initial aggregate
drop table if exists ofec_sched_a_aggregate_occupation_tmp;
create table ofec_sched_a_aggregate_occupation_tmp as
select
    cmte_id,
    rpt_yr + rpt_yr % 2 as cycle,
    contbr_occupation as occupation,
    sum(contb_receipt_amt) as total,
    count(contb_receipt_amt) as count
from fec_fitem_sched_a_vw
where rpt_yr >= :START_YEAR_AGGREGATE
and contb_receipt_amt is not null
and is_individual(contb_receipt_amt, receipt_tp, line_num, memo_cd, memo_text, contbr_id, cmte_id)
group by cmte_id, cycle, occupation
;

alter table ofec_sched_a_aggregate_occupation_tmp add column idx serial;
alter table ofec_sched_a_aggregate_occupation_tmp add constraint uq_sched_a_aggregate_occupation_tmp_cmte_id_cycle_occupation unique (cmte_id, cycle, occupation);

-- Create indices on aggregate
create index ofec_sched_a_aggregate_occupation_tmp_cmte_id on ofec_sched_a_aggregate_occupation_tmp(cmte_id);
create index ofec_sched_a_aggregate_occupation_tmp_cycle on ofec_sched_a_aggregate_occupation_tmp(cycle);
create index ofec_sched_a_aggregate_occupation_tmp_occupation on ofec_sched_a_aggregate_occupation_tmp(occupation);
create index ofec_sched_a_aggregate_occupation_tmp_total on ofec_sched_a_aggregate_occupation_tmp(total);
create index ofec_sched_a_aggregate_occupation_tmp_count on ofec_sched_a_aggregate_occupation_tmp(count);
create index ofec_sched_a_aggregate_occupation_tmp_cycle_cmte_id on ofec_sched_a_aggregate_occupation_tmp(cycle, cmte_id);

-- Remove previous aggregate and rename new aggregate
drop table if exists ofec_sched_a_aggregate_occupation;
alter table ofec_sched_a_aggregate_occupation_tmp rename to ofec_sched_a_aggregate_occupation;
select rename_indexes('ofec_sched_a_aggregate_occupation');
