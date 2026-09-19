# Increased and Repeated Clicking Behavior — Analysis Code and Data

Analysis code and data for the IEEE S&P 2027 paper on increased and repeated clicking
behaviour across four phishing simulations in a large university.

This repository reproduces the paper's quantitative results: the sample construction, the
descriptive click and compromise rates, the scale reliabilities, the H1 and H2 mediation
models, and the H3 between-person and within-person models, together with four of the
paper's figures.

## What you need

A machine with Docker and about 3 GB of free disk. No GPU, no special hardware, no
network access at analysis time. The image has been built and run on x86-64 Linux; it
should work anywhere Docker runs, though it has not been tested on Apple silicon.

Everything else — R, the 23 R packages, and pandoc — is installed by the Dockerfile.

## Reproducing the results

```bash
docker build -t repeat-clicker .
./run_analysis.sh
```

That writes `results/analysis.log` and the figures into `results/`.

Build takes about 40 seconds. The analysis takes about three minutes here: the baseline
m = 30 imputation, plus the H3 robustness checks — an m = 100 imputation and three
donor-pool variants (k = 1, 3, 5), each its own m = 100 imputation.

If you prefer to drive it yourself:

```bash
mkdir -p results && cp study_data_merged.xlsx Repeat_clicker_analysis_5.Rmd results/
docker run --rm --network none -v "$PWD/results":/work -w /work repeat-clicker \
  Rscript -e 'rmarkdown::render("Repeat_clicker_analysis_5.Rmd")'
```

`--network none` is deliberate. The image needs no network once built, and running with
networking disabled is the simplest proof of that.

## Why it is reproducible

`Dockerfile` builds on `rocker/r-ver:4.5.1`, which pins CRAN to a frozen Posit Package
Manager snapshot — `2025-10-30` by default, set as a build argument so it is visible and
overridable. Every package resolves to the version that snapshot served, so a rebuild in
a year installs what it installs today.

The image contains no data and no analysis code. The working directory is bind-mounted
at run time. This keeps the environment independent of the study material.

One trap worth knowing if you modify the Dockerfile: the base image's `Rprofile.site`
sets `HTTPUserAgent`, and Posit only serves prebuilt Linux binaries when R identifies
itself that way. Overwrite that file without the option and every package silently
compiles from source, turning a 40-second build into roughly 45 minutes.

## Mapping the paper's claims to the output

All values below were confirmed by running the analysis in this repository.

| Paper claim | Value in the paper | Where in the output |
|---|---|---|
| Final analysis sample | N = 986 | `N Original (df_analysis_filt): 986` |
| Repeat-clicking subset | N = 115 | `N mit vollständigem Exposure (4/4): 115` |
| Duplicate exclusions | 138 | `Raw duplicates (by anonymisedEmail): 138` |
| Attention-check exclusions | 419 | `[Strict check] Excluded: 419` |
| Click rates, simulations 1–4 | 4.5 / 17.6 / 18.0 / 33.6 % | `Click rates by simulation` |
| Compromise rates, simulations 1–4 | 0.4 / 5.1 / 6.0 / 9.0 % | `Compromise rates by simulation` |
| Mean age | 39.8 (SD 11.0) | `mean(df_analysis_filt$age_mean)` = 39.78, SD 10.99 |
| H1 model fit | χ²(15) = 180.71 | lavaan `Test Statistic 180.711` |
| H2 model fit | χ²(15) = 201.02 | lavaan `Test Statistic 201.021` |
| H1 indirect and total effects | all eight rows of `tab:H1_indirect` | `Defined Parameters`, H1 model |
| H2 indirect and total effects | all eight rows of `tab:H2_indirect` | `Defined Parameters`, H2 model |
| H3, optimism bias on repeat clicking | β = .406, Wald t(30.50) = 2.20, p = .035 | pooled GLM, `sum_z` table: 0.40622, 2.2010, df 30.50, p .0354 |
| H3 robustness, m = 100 | β = .429, p = .028 | second `sum_z` table: 0.42940, p .02838 |
| H3 robustness, PMM donor pools 1 / 3 / 5 | β = .429–.506, p = .020–.034 | `optimism_donor_results`: .5056/.0338, .4333/.0203, .4294/.0284 |
| H2 post hoc, training-link click | β = 0.23, z = 2.20, p = .028; age 0.35, z = 2.55, p = .011 | `glm(cybsafeLinkClicked ~ ...)`: 0.22783/2.195/.0282; 0.35253/2.549/.0108 |
| H3 post hoc, detection difficulty | β = 0.83, z = 4.71, OR = 2.30 | `H4 pooled fixed effects`: 0.8337, 4.71, OR 2.30 |
| H3 post hoc, variance from individual differences | ≈ 15 % | `mean(icc_vals)` = 0.1507 |
| Qualitative, inter-rater reliability | Cohen's κ = 0.881 | `results/qualitative.log`, `Cohen's kappa` |
| Qualitative, open-text reason counts | 13 / 12 / 3 / 2 / 2 / 1 / 1 | `results/qualitative.log`, `derived` column |
| Closed-format reasons for clicking, respondents choosing each option (multi-select, 67 answered) | 40 / 6 / 4 / 3 | `results/analysis.log`, `Closed-format reasons, respondents = 67`, then `df_predef_raw`, `n` column, leaving out the `Other reason:` row; asserted, so a mismatch fails the run |

Figures written to `results/`, all four used in the paper:

- `forest_plot_odds_ratios.pdf`
- `phishing_rates_combined_usenix.pdf`
- `clickcount_with_compromise_per_click_overlay.pdf`
- `self_reported_reasons_clicking_faceted.pdf`

## Known limitations

These are stated up front so readers do not have to discover them.

**Some reported numbers are not computed here.** The power analysis and the four
gender-category counts are reported in the paper but are not part of this document.

**Output is part German, part English.** Some console labels and headings are in German.
They are cosmetic and do not affect any result.

## Data statement

`study_data_merged.xlsx` is survey and phishing-simulation log data from staff at a
single university. It is de-identified: direct identifiers and unused directory-derived
quasi-identifiers were removed before publication, and the institution is
not named anywhere in it.

`anonymisedEmail` is a 44-character pseudonym, retained because deduplication needs it. It
was generated through a cryptographic ceremony designed so that neither the researchers nor
the institution's IT security group, separately or together, can recover a participant's
actual email address from it.

The analysis uses the staff-tenure column, as `years_org_num`, as a control in all five
models.

The three free-text survey fields are deliberately **kept**, having been screened for
identifying information. They are the raw material the qualitative coding worked from, and
`Qualitative_coding.xlsx` carries the same responses alongside the coders' labels, screened
to the same standard.

No column that was removed is referenced anywhere in the analysis, so the de-identification
cannot have changed a reported result. That is checked, not assumed.

`PROVENANCE.md` records how the data was collected, and `ETHICS.md` reproduces the paper's
ethics statement.

## Landing page

`landing_page_simulation_3.html` is the landing page participants reached from the
simulation 3 email (the "New user sign-on notification", February 2025, Microsoft
Defender). It shows the simulated email again with four cues to identify — the sender
address, the generic greeting, the threat of negative consequences and the misleading
link — followed by guidance on recognising and reporting phishing.

It is one self-contained file: open it in any browser. It needs no network and makes no
requests. It is not used by the analysis and is not built into the Docker image.

The page is the delivered one, made static and anonymised. The institution's name, logo
and domain are replaced by `[anonymized institution]` and `[anonymized domain]`; the
details the platform filled in for each participant (name, email address) appear as
`[bracketed placeholders]`. The page's own text is otherwise unchanged. The landing page
for simulation 4 had the same information. Landing pages for simulations 1 and 2 were not 
available to the researchers.


## Licence

The code and the landing page are **MIT** (`LICENSE`); the data is **CC BY 4.0** (`LICENSE-DATA`), matching the
existing Zenodo deposit. Creative Commons licences are not intended for software, hence
the split.

Cite the Zenodo deposit by its **concept DOI**, `10.5281/zenodo.18503743`, rather than a
version DOI, so the citation keeps resolving to the current version.

## Files

| File | What it is |
|---|---|
| `Repeat_clicker_analysis_5.Rmd` | The analysis. Runs top to bottom; chunks depend on earlier chunks |
| `study_data_merged.xlsx` | Survey and simulation data, 1625 responses |
| `Dockerfile` | Pinned R environment |
| `run_analysis.sh` | One-command reproduction |
| `Qualitative_coding.Rmd` | Derives Cohen's κ and the open-text category counts |
| `Qualitative_coding.xlsx` | The two coders' labels, the codebook, and the coded responses |
| `PROVENANCE.md` | How the data was collected, and how it was de-identified |
| `ETHICS.md` | The paper's ethics statement |
| `landing_page_simulation_3.html` | The landing page shown after the simulation 3 email, static and anonymised |
| `LICENSE` | MIT, covering the code and the landing page |
| `LICENSE-DATA` | CC BY 4.0, covering the data, with a responsible-use note |
