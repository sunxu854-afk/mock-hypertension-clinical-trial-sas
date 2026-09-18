\# Mock Hypertension Clinical Trial - SAS Programming Project

\## Overview

This project simulates a randomized clinical trial comparing Drug A with Placebo in 100 subjects with hypertension.

All data are simulated and do not represent real patients or a real clinical trial.

\## Study Design

\- Sample size: 100 subjects

\- Drug A: 50 subjects

\- Placebo: 50 subjects

\- Visits:

&#x20; - Baseline

&#x20; - Week 4

&#x20; - Week 8

&#x20; - Week 12

\## Simulated Raw Datasets

\### DM

Contains demographic information and randomized treatment assignment.

Variables include:

\- SUBJID

\- SITEID

\- AGE

\- SEX

\- RACE

\- ARM

\- RANDDT

\### VS

Contains longitudinal blood pressure measurements.

Variables include:

\- SUBJID

\- ARM

\- VISIT

\- VISITNUM

\- VISITDT

\- SBP

\- DBP

\### AE

Contains simulated adverse event records.

Variables include:

\- SUBJID

\- ARM

\- AESEQ

\- AETERM

\- SEVERITY

\- AESTDT

\- AEENDT

\## SAS Programming Skills

This project demonstrates:

\- DATA Step programming

\- DO loops

\- Conditional logic

\- RAND function

\- SAS dates

\- SET and MERGE

\- PROC SORT

\- NODUPKEY

\- PROC FREQ

\- PROC MEANS

\- PROC TTEST

\- PROC EXPORT

\- Basic clinical data QC

\## Main Analysis

The primary efficacy analysis compares change from baseline in systolic blood pressure at Week 12 between Drug A and Placebo.

\## Disclaimer

This repository is for educational purposes only. All study data are completely simulated.

