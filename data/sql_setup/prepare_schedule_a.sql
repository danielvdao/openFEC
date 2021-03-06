-- Drop the old nightly refresh retry table and function if they still exist.
drop table if exists ofec_sched_a_nightly_retries;
drop function if exists retry_processing_schedule_a_records(start_year integer);

-- Drop the old queues if they still exist.
drop table if exists ofec_sched_a_queue_new;
drop table if exists ofec_sched_a_queue_old;


-- Create trigger to maintain Schedule A for inserts and updates
-- These happen after a row is inserted/updated so that we can leverage pulling
-- the new record information from the view itself, which contains the data in
-- the structure that our tables expect it to be in.
create or replace function ofec_sched_a_insert_update() returns trigger as $$
declare
    start_year int = TG_ARGV[0]::int;
    view_row fec_fitem_sched_a_vw%ROWTYPE;
    child_table_name text;
begin
    select into view_row * from fec_fitem_sched_a_vw where sub_id = new.sub_id;

    -- Check to see if the resultset returned anything from the view.  If
    -- it did not, skip the processing of the record, otherwise we'll end
    -- up with a record full of NULL values.
    -- "FOUND" is a PL/pgSQL boolean variable set to false initially in
    -- any PL/pgSQL function and reset whenever certain statements are
    -- run, e.g., a "SELECT INTO..." statement.  For more information,
    -- visit here:
    -- https://www.postgresql.org/docs/current/static/plpgsql-statements.html#PLPGSQL-STATEMENTS-DIAGNOSTICS
    if FOUND then
        if view_row.election_cycle >= start_year then
            child_table_name = 'ofec_sched_a_' || get_partition_suffix(view_row.election_cycle);
            EXECUTE format('
            INSERT INTO %I
            (
                cmte_id,
                cmte_nm,
                contbr_id,
                contbr_nm,
                contbr_nm_first,
                contbr_m_nm,
                contbr_nm_last,
                contbr_prefix,
                contbr_suffix,
                contbr_st1,
                contbr_st2,
                contbr_city,
                contbr_st,
                contbr_zip,
                entity_tp,
                entity_tp_desc,
                contbr_employer,
                contbr_occupation,
                election_tp,
                fec_election_tp_desc,
                fec_election_yr,
                election_tp_desc,
                contb_aggregate_ytd,
                contb_receipt_dt,
                contb_receipt_amt,
                receipt_tp,
                receipt_tp_desc,
                receipt_desc,
                memo_cd,
                memo_cd_desc,
                memo_text,
                cand_id,
                cand_nm,
                cand_nm_first,
                cand_m_nm,
                cand_nm_last,
                cand_prefix,
                cand_suffix,
                cand_office,
                cand_office_desc,
                cand_office_st,
                cand_office_st_desc,
                cand_office_district,
                conduit_cmte_id,
                conduit_cmte_nm,
                conduit_cmte_st1,
                conduit_cmte_st2,
                conduit_cmte_city,
                conduit_cmte_st,
                conduit_cmte_zip,
                donor_cmte_nm,
                national_cmte_nonfed_acct,
                increased_limit,
                action_cd,
                action_cd_desc,
                tran_id,
                back_ref_tran_id,
                back_ref_sched_nm,
                schedule_type,
                schedule_type_desc,
                line_num,
                image_num,
                file_num,
                link_id,
                orig_sub_id,
                sub_id,
                filing_form,
                rpt_tp,
                rpt_yr,
                election_cycle,
                timestamp,
                pg_date,
                pdf_url,
                contributor_name_text,
                contributor_employer_text,
                contributor_occupation_text,
                is_individual,
                clean_contbr_id,
                two_year_transaction_period,
                line_number_label
            )
            VALUES
            (
                $1.cmte_id,
                $1.cmte_nm,
                $1.contbr_id,
                $1.contbr_nm,
                $1.contbr_nm_first,
                $1.contbr_m_nm,
                $1.contbr_nm_last,
                $1.contbr_prefix,
                $1.contbr_suffix,
                $1.contbr_st1,
                $1.contbr_st2,
                $1.contbr_city,
                $1.contbr_st,
                $1.contbr_zip,
                $1.entity_tp,
                $1.entity_tp_desc,
                $1.contbr_employer,
                $1.contbr_occupation,
                $1.election_tp,
                $1.fec_election_tp_desc,
                $1.fec_election_yr,
                $1.election_tp_desc,
                $1.contb_aggregate_ytd,
                $1.contb_receipt_dt,
                $1.contb_receipt_amt,
                $1.receipt_tp,
                $1.receipt_tp_desc,
                $1.receipt_desc,
                $1.memo_cd,
                $1.memo_cd_desc,
                $1.memo_text,
                $1.cand_id,
                $1.cand_nm,
                $1.cand_nm_first,
                $1.cand_m_nm,
                $1.cand_nm_last,
                $1.cand_prefix,
                $1.cand_suffix,
                $1.cand_office,
                $1.cand_office_desc,
                $1.cand_office_st,
                $1.cand_office_st_desc,
                $1.cand_office_district,
                $1.conduit_cmte_id,
                $1.conduit_cmte_nm,
                $1.conduit_cmte_st1,
                $1.conduit_cmte_st2,
                $1.conduit_cmte_city,
                $1.conduit_cmte_st,
                $1.conduit_cmte_zip,
                $1.donor_cmte_nm,
                $1.national_cmte_nonfed_acct,
                $1.increased_limit,
                $1.action_cd,
                $1.action_cd_desc,
                $1.tran_id,
                $1.back_ref_tran_id,
                $1.back_ref_sched_nm,
                $1.schedule_type,
                $1.schedule_type_desc,
                $1.line_num,
                $1.image_num,
                $1.file_num,
                $1.link_id,
                $1.orig_sub_id,
                $1.sub_id,
                $1.filing_form,
                $1.rpt_tp,
                $1.rpt_yr,
                $1.election_cycle,
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP,
                image_pdf_url($1.image_num),
                to_tsvector(concat($1.contbr_nm, '' '', $1.contbr_id)),
                to_tsvector($1.contbr_employer),
                to_tsvector($1.contbr_occupation),
                is_individual($1.contb_receipt_amt, $1.receipt_tp, $1.line_num, $1.memo_cd, $1.memo_text),
                clean_repeated($1.contbr_id, $1.cmte_id),
                get_cycle($1.rpt_yr),
                expand_line_number($1.filing_form, $1.line_num)
            )
            ON CONFLICT (sub_id) DO UPDATE
            SET
                cmte_id = $1.cmte_id,
                cmte_nm = $1.cmte_nm,
                contbr_id = $1.contbr_id,
                contbr_nm = $1.contbr_nm,
                contbr_nm_first = $1.contbr_nm_first,
                contbr_m_nm = $1.contbr_m_nm,
                contbr_nm_last = $1.contbr_nm_last,
                contbr_prefix = $1.contbr_prefix,
                contbr_suffix = $1.contbr_suffix,
                contbr_st1 = $1.contbr_st1,
                contbr_st2 = $1.contbr_st2,
                contbr_city = $1.contbr_city,
                contbr_st = $1.contbr_st,
                contbr_zip = $1.contbr_zip,
                entity_tp = $1.entity_tp,
                entity_tp_desc = $1.entity_tp_desc,
                contbr_employer = $1.contbr_employer,
                contbr_occupation = $1.contbr_occupation,
                election_tp = $1.election_tp,
                fec_election_tp_desc = $1.fec_election_tp_desc,
                fec_election_yr = $1.fec_election_yr,
                election_tp_desc = $1.election_tp_desc,
                contb_aggregate_ytd = $1.contb_aggregate_ytd,
                contb_receipt_dt = $1.contb_receipt_dt,
                contb_receipt_amt = $1.contb_receipt_amt,
                receipt_tp = $1.receipt_tp,
                receipt_tp_desc = $1.receipt_tp_desc,
                receipt_desc = $1.receipt_desc,
                memo_cd = $1.memo_cd,
                memo_cd_desc = $1.memo_cd_desc,
                memo_text = $1.memo_text,
                cand_id = $1.cand_id,
                cand_nm = $1.cand_nm,
                cand_nm_first = $1.cand_nm_first,
                cand_m_nm = $1.cand_m_nm,
                cand_nm_last = $1.cand_nm_last,
                cand_prefix = $1.cand_prefix,
                cand_suffix = $1.cand_suffix,
                cand_office = $1.cand_office,
                cand_office_desc = $1.cand_office_desc,
                cand_office_st = $1.cand_office_st,
                cand_office_st_desc = $1.cand_office_st_desc,
                cand_office_district = $1.cand_office_district,
                conduit_cmte_id = $1.conduit_cmte_id,
                conduit_cmte_nm = $1.conduit_cmte_nm,
                conduit_cmte_st1 = $1.conduit_cmte_st1,
                conduit_cmte_st2 = $1.conduit_cmte_st2,
                conduit_cmte_city = $1.conduit_cmte_city,
                conduit_cmte_st = $1.conduit_cmte_st,
                conduit_cmte_zip = $1.conduit_cmte_zip,
                donor_cmte_nm = $1.donor_cmte_nm,
                national_cmte_nonfed_acct = $1.national_cmte_nonfed_acct,
                increased_limit = $1.increased_limit,
                action_cd = $1.action_cd,
                action_cd_desc = $1.action_cd_desc,
                tran_id = $1.tran_id,
                back_ref_tran_id = $1.back_ref_tran_id,
                back_ref_sched_nm = $1.back_ref_sched_nm,
                schedule_type = $1.schedule_type,
                schedule_type_desc = $1.schedule_type_desc,
                line_num = $1.line_num,
                image_num = $1.image_num,
                file_num = $1.file_num,
                link_id = $1.link_id,
                orig_sub_id = $1.orig_sub_id,
                filing_form = $1.filing_form,
                rpt_tp = $1.rpt_tp,
                rpt_yr = $1.rpt_yr,
                election_cycle = $1.election_cycle,
                timestamp = CURRENT_TIMESTAMP,
                pg_date = CURRENT_TIMESTAMP,
                pdf_url = image_pdf_url($1.image_num),
                contributor_name_text = to_tsvector(concat($1.contbr_nm, '' '', $1.contbr_id)),
                contributor_employer_text = to_tsvector($1.contbr_employer),
                contributor_occupation_text = to_tsvector($1.contbr_occupation),
                is_individual = is_individual($1.contb_receipt_amt, $1.receipt_tp, $1.line_num, $1.memo_cd, $1.memo_text),
                clean_contbr_id = clean_repeated($1.contbr_id, $1.cmte_id),
                two_year_transaction_period = get_cycle($1.rpt_yr),
                line_number_label = expand_line_number($1.filing_form, $1.line_num)
            WHERE
                %I.sub_id = $1.sub_id',
                child_table_name, child_table_name) USING view_row;
            PERFORM increment_sched_a_aggregates(view_row);
        end if;
    end if;

    RETURN NULL; -- result is ignored since this is an AFTER trigger
end
$$ language plpgsql;


-- Create trigger to maintain Schedule A deletes and updates
-- These happen before a row is removed/updated so that we can leverage pulling
-- the new record information from the view itself, which contains the data in
-- the structure that our tables expect it to be in.
create or replace function ofec_sched_a_delete_update() returns trigger as $$
declare
    start_year int = TG_ARGV[0]::int;
    view_row fec_fitem_sched_a_vw%ROWTYPE;
begin
        select into view_row * from fec_fitem_sched_a_vw where sub_id = old.sub_id;

        -- Check to see if the resultset returned anything from the view.  If
        -- it did not, skip the processing of the record, otherwise we'll end
        -- up with a record full of NULL values.
        -- "FOUND" is a PL/pgSQL boolean variable set to false initially in
        -- any PL/pgSQL function and reset whenever certain statements are
        -- run, e.g., a "SELECT INTO..." statement.  For more information,
        -- visit here:
        -- https://www.postgresql.org/docs/current/static/plpgsql-statements.html#PLPGSQL-STATEMENTS-DIAGNOSTICS
        if FOUND then
            if view_row.election_cycle >= start_year then
                IF tg_op = 'DELETE' THEN
                    DELETE FROM ofec_sched_a_master WHERE sub_id = view_row.sub_id;
                END IF;
                PERFORM decrement_sched_a_aggregates(view_row);
            end if;
        end if;

    if tg_op = 'DELETE' then
        return old;
    elsif tg_op = 'UPDATE' then
        -- We have to return new here because this record is intended to change
        -- with an update.
        return new;
    end if;
end
$$ language plpgsql;


-- Create new triggers
drop trigger if exists nml_sched_a_after_trigger on disclosure.nml_sched_a;
create trigger nml_sched_a_after_trigger after insert or update
    on disclosure.nml_sched_a for each row execute procedure ofec_sched_a_insert_update(:START_YEAR_AGGREGATE);

drop trigger if exists nml_sched_a_before_trigger on disclosure.nml_sched_a;
create trigger nml_sched_a_before_trigger before delete or update
    on disclosure.nml_sched_a for each row execute procedure ofec_sched_a_delete_update(:START_YEAR_AGGREGATE);

drop trigger if exists f_item_sched_a_after_trigger on disclosure.f_item_receipt_or_exp;
create trigger f_item_sched_a_after_trigger after insert or update
    on disclosure.f_item_receipt_or_exp for each row execute procedure ofec_sched_a_insert_update(:START_YEAR_AGGREGATE);

drop trigger if exists f_item_sched_a_before_trigger on disclosure.f_item_receipt_or_exp;
create trigger f_item_sched_a_before_trigger before delete or update
    on disclosure.f_item_receipt_or_exp for each row execute procedure ofec_sched_a_delete_update(:START_YEAR_AGGREGATE);

CREATE OR REPLACE FUNCTION increment_sched_a_aggregates(view_row fec_fitem_sched_a_vw) RETURNS VOID AS $$
BEGIN
    IF view_row.contb_receipt_amt IS NOT NULL AND is_individual(view_row.contb_receipt_amt, view_row.receipt_tp, view_row.line_num, view_row.memo_cd, view_row.memo_text, view_row.contbr_id, view_row.cmte_id) THEN
        INSERT INTO ofec_sched_a_aggregate_employer
            (cmte_id, cycle, employer, total, count)
        VALUES
            (view_row.cmte_id, view_row.election_cycle, view_row.contbr_employer, view_row.contb_receipt_amt, 1)
        ON CONFLICT ON CONSTRAINT uq_sched_a_aggregate_employer_cmte_id_cycle_employer DO UPDATE
        SET
            total = ofec_sched_a_aggregate_employer.total + excluded.total,
            count = ofec_sched_a_aggregate_employer.count + excluded.count;
        INSERT INTO ofec_sched_a_aggregate_occupation
            (cmte_id, cycle, occupation, total, count)
        VALUES
            (view_row.cmte_id, view_row.election_cycle, view_row.contbr_occupation, view_row.contb_receipt_amt, 1)
        ON CONFLICT ON CONSTRAINT uq_sched_a_aggregate_occupation_cmte_id_cycle_occupation DO UPDATE
        SET
            total = ofec_sched_a_aggregate_occupation.total + excluded.total,
            count = ofec_sched_a_aggregate_occupation.count + excluded.count;
        INSERT INTO ofec_sched_a_aggregate_state
            (cmte_id, cycle, state, state_full, total, count)
        VALUES
            (view_row.cmte_id, view_row.election_cycle, view_row.contbr_st, expand_state(view_row.contbr_st), view_row.contb_receipt_amt, 1)
        ON CONFLICT ON CONSTRAINT uq_ofec_sched_a_aggregate_state_cmte_id_cycle_state DO UPDATE
        SET
            total = ofec_sched_a_aggregate_state.total + excluded.total,
            count = ofec_sched_a_aggregate_state.count + excluded.count;
        INSERT INTO ofec_sched_a_aggregate_zip
            (cmte_id, cycle, zip, state, state_full, total, count)
        VALUES
            (view_row.cmte_id, view_row.election_cycle, view_row.contbr_zip, view_row.contbr_st, expand_state(view_row.contbr_st), view_row.contb_receipt_amt, 1)
        ON CONFLICT ON CONSTRAINT uq_ofec_sched_a_aggregate_zip_cmte_id_cycle_zip DO UPDATE
        SET
            total = ofec_sched_a_aggregate_zip.total + excluded.total,
            count = ofec_sched_a_aggregate_zip.count + excluded.count;
        INSERT INTO ofec_sched_a_aggregate_size
            (cmte_id, cycle, size, total, count)
        VALUES
            (view_row.cmte_id, view_row.election_cycle, contribution_size(view_row.contb_receipt_amt), view_row.contb_receipt_amt, 1)
        ON CONFLICT ON CONSTRAINT uq_ofec_sched_a_aggregate_size_cmte_id_cycle_size DO UPDATE
        SET
            total = ofec_sched_a_aggregate_size.total + excluded.total,
            count = ofec_sched_a_aggregate_size.count + excluded.count;
    END IF;
END
$$ language plpgsql;

CREATE OR REPLACE FUNCTION decrement_sched_a_aggregates(view_row fec_fitem_sched_a_vw) RETURNS VOID AS $$
BEGIN
    IF view_row.contb_receipt_amt IS NOT NULL AND is_individual(view_row.contb_receipt_amt, view_row.receipt_tp, view_row.line_num, view_row.memo_cd, view_row.memo_text, view_row.contbr_id, view_row.cmte_id) THEN
        UPDATE ofec_sched_a_aggregate_employer
        SET
            total = ofec_sched_a_aggregate_employer.total - view_row.contb_receipt_amt,
            count = ofec_sched_a_aggregate_employer.count - 1
        WHERE
            (cmte_id, cycle, employer) = (view_row.cmte_id, view_row.election_cycle, view_row.contbr_employer);
        UPDATE ofec_sched_a_aggregate_occupation
        SET
            total = ofec_sched_a_aggregate_occupation.total - view_row.contb_receipt_amt,
            count = ofec_sched_a_aggregate_occupation.count - 1
        WHERE
            (cmte_id, cycle, occupation) = (view_row.cmte_id, view_row.election_cycle, view_row.contbr_occupation);
        UPDATE ofec_sched_a_aggregate_state
        SET
            total = ofec_sched_a_aggregate_state.total - view_row.contb_receipt_amt,
            count = ofec_sched_a_aggregate_state.count - 1
        WHERE
            (cmte_id, cycle, state) = (view_row.cmte_id, view_row.election_cycle, view_row.contbr_st);
        UPDATE ofec_sched_a_aggregate_zip
        SET
            total = ofec_sched_a_aggregate_zip.total - view_row.contb_receipt_amt,
            count = ofec_sched_a_aggregate_zip.count - 1
        WHERE
            (cmte_id, cycle, zip) = (view_row.cmte_id, view_row.election_cycle, view_row.contbr_zip);
        UPDATE ofec_sched_a_aggregate_size
        SET
            total = ofec_sched_a_aggregate_size.total - view_row.contb_receipt_amt,
            count = ofec_sched_a_aggregate_size.count - 1
        WHERE
            (cmte_id, cycle, size) = (view_row.cmte_id, view_row.election_cycle, contribution_size(view_row.contb_receipt_amt));
    END IF;
END
$$ language plpgsql;

-- Drop the old trigger functions if they still exist.
drop function if exists ofec_sched_a_insert_update_queues();
drop function if exists ofec_sched_a_delete_update_queues();
