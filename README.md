# Increased and Repeated Clicking Behavior — Analysis Code and Data

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18503743.svg)](https://doi.org/10.5281/zenodo.18503743)

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

That writes into `results/`:

| File | What it is |
|---|---|
| `analysis.log` | Every result the analysis prints, in numbered sections, one per part of the paper; see below |
| `qualitative.log` | Cohen's κ and the open-text category counts, from the coders' workbook |
| `fig2_clicktrend.pdf` | Figure 2 (`fig:clicktrend`) |
| `fig4_click_histogram.pdf` | Figure 4 (`fig:click_histogram`) |
| `fig5_forest_plot_h3.pdf` | Figure 5 (`fig:forest_plot_h3`) |
| `fig6_selfreportedreasons.pdf` | Figure 6 (`fig:selfreportedreasons`) |
| `supplementary_plots.pdf` | Every plot the analysis draws, including those not in the paper; see below |

Each figure is named after its number and `\label` in the paper. Figures 1 and 3 are
diagrams drawn by hand, and Figures 7 to 10 are screenshots of the simulated emails, so
none of those six is generated here.

Build takes about 40 seconds. The analysis takes about two minutes here: the baseline
m = 30 imputation, plus the H3 robustness check: three m = 100 imputations, one per
donor-pool size (k = 1, 3, 5). The k = 5 run is also the paper's m = 100 result, since
five donors is the default the baseline uses.

If you prefer to drive it yourself:

```bash
mkdir -p results && cp study_data_merged.xlsx Repeat_clicker_analysis_5.Rmd results/
docker run --rm --network none -v "$PWD/results":/work -w /work repeat-clicker \
  Rscript -e 'rmarkdown::render("Repeat_clicker_analysis_5.Rmd")'
```

`--network none` is deliberate. The image needs no network once built, and running with
networking disabled is the simplest proof of that.

### Reading `analysis.log`

The log holds results only, not code. It opens with a short guide and a table of
contents giving the line on which each section starts. Each section starts with a banner
naming the part of the paper it supports, for example:

```
################################################################################
### 10. H1: parallel mediation, compromise level in simulation 3 -> simulation 4
###    Paper: Section 4.2 (RQ1, 'Preregistered analysis H1'); Table 4 (tab:H1_indirect)
################################################################################
```

Output the paper does not use, such as the data-quality checks, is in sections marked
`not reported`. Within a section, a line starting `>>> ` names the claim in the paper
and which of the values printed after it the claim comes from, so searching for `>>> `
steps through every reported value in order. In the code and the log, `sim0`, `sim0.5`,
`sim1` and `sim2` are the paper's simulations 1 to 4.

The code for any section is found by searching `Repeat_clicker_analysis_5.Rmd` for the
section's title: each banner is printed by a `section()` call at that point.

`qualitative.log` is laid out the same way, from `Qualitative_coding.Rmd`, in three
sections of its own.

### `supplementary_plots.pdf`

Every plot the analysis draws, in order, one per page: the straightlining distribution
(page 1); the variable histograms (pages 2 to 4), the training-intention scatter plots
(page 5) and the Cook's distances (page 6) behind the assumption checks in Section 4.1.1;
then Figures 5, 4 and 6 again. None of pages 1 to 6 is in the paper. It is what R would
otherwise write to its default `Rplots.pdf`.

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

Section, figure and table numbers are those of the camera-ready paper. "Log §" is the
numbered section of `results/analysis.log`; the `>>> ` line in that section says which
printed value each claim is read from.

| Where in the paper | Claim | Value in the paper | Log § |
|---|---|---|---|
| Section 3.2.1 | Recorded responses; duplicate exclusions | 1625; 138 | 1 |
| Section 3.2.1 | Attention-check exclusions | 419 | 1 |
| Section 3.2.1 | Exposure exclusions; final analysis sample | 82; N = 986 | 1 |
| Section 3.2.1 | Academic and non-academic staff | 455 / 531 | 6 |
| Section 3.2.1 | Mean age | 39.8 (SD 11.0) | 6 |
| Table 1 | Scale reliabilities (α) | .74, .69, .86, .86, .88, .671 / .832, .89 | 8 |
| Table 3 (Appendix C) | Correlations between the seven scales | every cell | 4 |
| Section 4.1, Figure 2 | Click rates, simulations 1–4 | 4.5 / 17.6 / 18.0 / 33.6 % | 5 and 12 |
| Section 4.1, Figure 2 | Compromise rates, simulations 1–4 | 0.4 / 5.1 / 6.0 / 9.0 % | 5 and 12 |
| Section 4.1.1 | Variance inflation factors; Cook's distance | all < 2; all < 1 | 9 |
| Section 4.2 | H1 model fit | χ²(15) = 180.71 | 10 |
| Section 4.2, Table 4 | H1 indirect and total effects, including the c-path | all eight rows; B = 0.09, p = .048 | 10 |
| Section 4.2 | Post hoc H1, clicks | McNemar χ²(1) = 64.31; 259 vs 105 transitions | 11 |
| Section 4.2 | Post hoc H1, compromises | McNemar χ²(1) = 6.57; 79 vs 49 transitions | 11 |
| Section 4.3 | H2 model fit | χ²(15) = 201.02 | 13 |
| Section 4.3, Table 5, Figure 3 | H2 indirect and total effects; path coefficients | all eight rows | 13 |
| Section 4.3 | Training-link clicks | 67 (6.8 %) | 14 |
| Section 4.3 | Post hoc H2, training intention; age | B = 0.23, z = 2.20, p = .028; B = 0.35, z = 2.55, p = .011 | 14 |
| Section 4.4 | Repeat-clicking subset | N = 115 | 15 |
| Section 4.4, Table 6 | H3, optimism bias, and every other row | β = .406, Wald t(30.50) = 2.20, p = .035 | 15 |
| Section 4.4, Figure 5 | H3 odds ratios with 95 % intervals | as plotted | 15 |
| Section 4.4, Figure 4 | Participants by number of clicks; compromise per click | as plotted | 16 |
| Section 4.4 | H3 robustness, m = 100 | β = .429, p = .028 | 17 (the donors = 5 row) |
| Section 4.4 | H3 robustness, PMM donor pools 1 / 3 / 5 | β = .429–.506, p = .020–.034 | 17 |
| Section 4.4, Table 7 | Post hoc H3, detection difficulty, and every other row | B = 0.83, z = 4.71, OR = 2.30 | 18 |
| Section 4.4 | Post hoc H3, variance from individual differences | ≈ 15 % | 18 |
| Section 4.5, Figure 6 | Closed-format reasons for clicking (multi-select, 67 answered) | 40 / 6 / 4 / 3 | 19 |
| Section 4.5 | Inter-rater reliability | Cohen's κ = 0.881 | `qualitative.log` 1 |
| Section 4.5 | Raters' disagreements on the clicking reasons | 1 of 34 | `qualitative.log` 2 |
| Section 4.5, Figure 6 | Open-text reason counts | 13 / 12 / 3 / 2 / 2 / 1 / 1 | `qualitative.log` 3 |

The closed-format counts, κ, the disagreement and the open-text counts are asserted as
well as printed, so a mismatch fails the run; `qualitative.log` records each assertion
as a `Check passed:` line.

## Known limitations

These are stated up front so readers do not have to discover them.

**Some reported numbers are not computed here.** The power analysis and the four
gender-category counts are reported in the paper but are not part of this document.

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


## License

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
