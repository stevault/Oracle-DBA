explain plan for select * from dw_st.v_edw_submission_full;
REM explain plan for select /*+ PARALLEL(X,8) */ * from dw_st.v_edw_submission_full x;
select * from TABLE(dbms_xplan.display());

