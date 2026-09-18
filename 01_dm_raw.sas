/*========================================================
  Project 01
  Create Raw demograpic Data
========================================================*/
data dm_raw;
    call streaminit(2026);
	length subjid $7 siteid $6 sex $1 race $5 arm $7;
	do id=1 to 100;
        subjid=cats('SUBJ',put(id,z3.));
	    age=40+floor(rand('uniform')*36);
	    if rand('uniform')<0.5 then sex='M';
	    else sex='F';
	    siteid=cats('SITE',put(1+floor(rand('uniform')*5),z2.));
	    u=rand('uniform');
	    if u<0.70 then race='ASIAN';
	    else if u<0.85 then race='WHITE';
	    else race='OTHER';
		a=rand('uniform');
	    if id<=50 then arm='Drug A';
	    else arm='Placebo';
	    randdt='01jan2026'd+floor(rand('uniform')*60);
	    format randdt date9.;
	    output;
   end;
   drop id u;
run;
proc sort data=dm_raw;
      by a;
run;
data dm_raw;
     set dm_raw;
	 subjid=cats('SUBJ',put(_n_,z3.));
	 drop a;
run;
proc print data=dm_raw(obs=10);
run;
proc contents data=dm_raw;
run;
proc means data=dm_raw n mean std min max;
     var age;
run;
proc freq  data=dm_raw;
    tables sex race siteid arm;
run;

/*========================================================
  Project 02
  Create Raw Vital Signs Data
========================================================*/

data vs_raw;
    set dm_raw;
    length visit $8;
	/*固定随机种子，保证每次运行 结果一致*/
    if _n_ = 1 then call streaminit(2027);
	/*为每位 受试者生成一次基线血 压*/
    base_sbp = round(rand('normal',155,10));
    base_dbp = round(rand('normal',95,6));
	/*每位 受试者生成4次随访*/
    do visitnum = 0,4,8,12;
        if visitnum = 0 then visit = 'Baseline';
        else if visitnum = 4 then visit = 'Week 4';
        else if visitnum = 8 then visit = 'Week 8';
        else if visitnum = 12 then visit = 'Week 12';
        /*设置 不同治组的 平均治疗效  应*/
        if visitnum = 0 then do;
            effect_sbp = 0;
            effect_dbp = 0;
        end;
        else if arm = 'Drug A' then do;
            if visitnum = 4 then do;
                effect_sbp = -5;
                effect_dbp = -3;
            end;
            else if visitnum = 8 then do;
                effect_sbp = -9;
                effect_dbp = -5;
            end;
            else if visitnum = 12 then do;
                effect_sbp = -12;
                effect_dbp = -7;
            end;
        end;

        else if arm = 'Placebo' then do;
            if visitnum = 4 then do;
                effect_sbp = -1;
                effect_dbp = -1;
            end;
            else if visitnum = 8 then do;
                effect_sbp = -3;
                effect_dbp = -1;
            end;
            else if visitnum = 12 then do;
                effect_sbp = -4;
                effect_dbp = -2;
            end;
        end;
		/*baseline生成实际观察到  的 血 压*/
        if visitnum = 0 then do;
            sbp = base_sbp;
            dbp = base_dbp;
        end;
		/*治疗后加入个体波动值*/
        else do;
            error_sbp = rand('normal',0,4);
            error_dbp = rand('normal',0,3);
            sbp = round(base_sbp + effect_sbp + error_sbp);
            dbp = round(base_dbp+ effect_dbp+ error_dbp);
        end;
		/*创 建随访日 期*/
        visitdt = randdt + visitnum*7;
        format visitdt date9.;
		/*每次循环输出 一条记录*/
        output;
    end;
	/*删 除模拟过程中使用的 辅助变量*/
    drop base_sbp
         base_dbp
         effect_sbp
         effect_dbp
         error_sbp
         error_dbp
         randdt
         race
         sex
         age
         siteid;

run;
proc sort data=vs_raw;
    by subjid visitnum;
run;
proc print data=vs_raw(obs=10);
run;
proc contents data=vs_raw;
run;
proc freq data=vs_raw;
    tables visitnum visit arm;
run;
proc freq data=vs_raw;
    tables arm*visit;
run;
proc means data=vs_raw n mean std min max maxdec=1;
    class arm visitnum;
    var sbp dbp;
run;
data baseline;
    set vs_raw;
    if visitnum = 0;
    keep subjid sbp dbp;
    rename sbp = base_sbp
           dbp = base_dbp;
run;
proc sort data=vs_raw;
    by subjid;
run;

proc sort data=baseline;
    by subjid;
run;

data vs_analysis;
    merge vs_raw
          baseline;
    by subjid;

    chg_sbp = sbp - base_sbp;
    chg_dbp = dbp - base_dbp;
run;
proc print data=vs_analysis(obs=20);
    var subjid arm visit visitnum
        base_sbp sbp chg_sbp;
run;
proc means data=vs_analysis  n mean std min max maxdec=1;

    class arm visitnum;

    var chg_sbp chg_dbp;
run;
data week12;
    set vs_analysis;
    if visitnum = 12;
run;
proc means data=week12 n mean std min max maxdec=1;
    class arm;
    var chg_sbp;
run;
proc ttest data=week12;
    class arm;
    var chg_sbp;
run;
/*quanlity control*/;
proc freq data=vs_analysis;
    where visitnum = 0;
    tables chg_sbp;
run;

proc freq data=vs_analysis noprint;
    tables subjid /out=subject_count;
run;
proc print data=subject_count;
    where count ne 4;
run;

/*========================================================
  Project 03
  Create Raw Adverse Event Data
========================================================*/
data ae_raw;
    set dm_raw;
    length aeterm   $20
           severity $8;
    if _n_ = 1 then call streaminit(2028);
    r = rand('uniform');
    if arm = 'Drug A' then do;
        if r < 0.55 then n_ae = 0;
        else if r < 0.90 then n_ae = 1;
        else n_ae = 2;
    end;
    else if arm = 'Placebo' then do;
        if r < 0.70 then n_ae = 0;
        else if r < 0.95 then n_ae = 1;
        else n_ae = 2;
    end;
    /*------------------------------------------
      2. 对有AEd的 受试者逐条生成
    ------------------------------------------*/
    do aeseq =  1 to n_ae;
        /* AE名称 */
        term_rand =
            1 + floor(rand('uniform') * 5);
        if term_rand = 1 then
            aeterm = 'Headache';
        else if term_rand = 2 then
            aeterm = 'Dizziness';
        else if term_rand = 3 then
            aeterm = 'Nausea';
        else if term_rand = 4 then
            aeterm = 'Fatigue';
        else if term_rand = 5 then
            aeterm = 'Cough';
        /*--------------------------------------
          3. 严重程度
        --------------------------------------*/
        sev_rand = rand('uniform');
        if sev_rand < 0.70 then
            severity = 'MILD';
        else if sev_rand < 0.95 then
            severity = 'MODERATE';
        else
            severity = 'SEVERE';
        /*--------------------------------------
          4. AE开始日 期随机化后0~83天之间
        --------------------------------------*/
        aestdt = randdt + floor(rand('uniform') * 84);
        /* AE持续1~10天 */
        duration =1 + floor(rand('uniform') * 10);
        aeendt =aestdt + duration;
        format aestdt aeendt date9.;
        output;
    end;
    keep subjid
         arm
         aeseq
         aeterm
         severity
         aestdt
         aeendt;
run;
proc print data=ae_raw(obs=20);
run;
proc contents data=ae_raw;
run;
proc freq data=ae_raw;
    tables aeterm severity;
run;
proc freq data=ae_raw;
    tables arm*aeterm;
run;
proc freq data=ae_raw;
    tables arm;
run;
/*统计至少发生1个 AE 的 受试者*/
proc sort data=ae_raw
          out=ae_subject
          nodupkey;
    by arm subjid;
run;
proc freq data=ae_subject;
    tables arm;
run;
proc freq data=dm_raw noprint;
    tables arm / out=denom;
run;
proc print data=denom;
run;
proc freq data=ae_subject noprint;
    tables arm / out=anyae;
run;
data anyae;
    set anyae;
    ae_n = count;
    keep arm ae_n;
run;
data denom;
    set denom;
    total_n = count;
    keep arm total_n;
run;
proc sort data=denom;
    by arm;
run;
proc sort data=anyae;
    by arm;
run;
data anyae_summary;
    merge denom anyae;
    by arm;
    pct = ae_n / total_n * 100;
run;
data anyae_summary;
    set anyae_summary;
    length display $20;
    display =cats(put(ae_n, 3.) ,' (',put(pct, 5.1), '%)');
run;
proc sort data=ae_raw
          out=ae_term_subject
          nodupkey;
    by arm subjid aeterm;
run;
proc freq data=ae_term_subject noprint;
    tables arm*aeterm
        / out=ae_term_count;
run;

libname proj 'D:\SAS_Project01\data';
proc copy in=work out=proj;
    select dm_raw vs_raw ae_raw;
run;


proc export data=dm_raw
    outfile='D:\SAS_Project01\data\dm_raw.xlsx'
    dbms=xlsx
    replace;
run;

proc export data=vs_raw
    outfile='D:\SAS_Project01\data\vs_raw.xlsx'
    dbms=xlsx
    replace;
run;

proc export data=ae_raw
    outfile='D:\SAS_Project01\data\ae_raw.xlsx'
    dbms=xlsx
    replace;
run;
