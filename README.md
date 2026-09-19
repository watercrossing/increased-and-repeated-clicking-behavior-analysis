# Increased and Repeated Clicking Behavior — Artifact

Analysis code and data for the IEEE S&P 2027 paper on increased and repeated clicking
behaviour across four phishing simulations in a large university.

This artifact reproduces the paper's quantitative results: the sample construction, the
descriptive click and compromise rates, the scale reliabilities, the H1 and H2 mediation
models, and the H3 between-person and within-person models, together with four of the
paper's figures.

## Badges claimed

Available, Functional, and Reproduced.

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

Build takes about 40 seconds and the analysis about 90 seconds, so the whole thing is
under three minutes. It is well inside the one-day budget; no scaled-down variant is
needed.

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

## Which version of the paper this reproduces

This artifact reproduces the **submitted** version of the paper. This repo contains a 
second branch,  **camera-ready**, which is the version we intend to publish to Zenodo
after AE review.

That distinction turns out to matter less than it sounds. Comparing the submitted and
revised manuscripts token by token, **no reported number changed between them**. Every
numeric difference is an addition to the revised version, in two places:

- the optimism-bias sub-scale reliabilities, α = .671 for self-ratings and α = .832 for
  peer ratings. This artifact **does** produce both, exactly.
- a robustness paragraph for the H3 optimism-bias effect, varying the number of
  imputations and the PMM donor pool. It was added for the revised version and is not
  part of the submitted paper, so this branch does not reproduce it.

So every figure in the table below holds for both versions of the paper.

## Mapping the paper's claims to the output

All values below were confirmed by running this artifact.

| Paper claim | Value in the paper | Where in the output |
|---|---|---|
| Final analysis sample | N = 986 | `N Original (df_analysis_filt): 986` |
| Repeat-clicking subset | N = 115 | `N mit vollständigem Exposure (4/4): 115` |
| Duplicate exclusions | 138 | `Raw duplicates (by anonymisedEmail): 138` |
| Attention-check exclusions | 419 | `[Strict check] Excluded: 419` |
| Click rates, simulations 1–4 | 4.5 / 17.6 / 18.0 / 33.6 % | `Click rates by simulation` |
| Compromise rates, simulations 1–4 | 0.4 / 5.1 / 6.0 / 9.0 % | `Compromise rates by simulation` |
| H3, optimism bias on repeat clicking | β = 0.42, SE = 0.18, p = .029 | pooled GLM, `sum_z` table |
| H3 post hoc, detection difficulty | β = 0.83, z = 4.64, OR = 2.30 | `H4 pooled fixed effects` |
| H3 post hoc, optimism bias | β = 0.26, SE = 0.19, p = .157 | `H4 pooled fixed effects` |
| H3 post hoc, variance from individual differences | ≈ 16 % | `mean(icc_vals)` = 0.159 |
| Qualitative, inter-rater reliability | Cohen's κ = 0.881 | `results/qualitative.log`, `Cohen's kappa` |
| Qualitative, open-text reason counts | 13 / 12 / 3 / 2 / 2 / 1 / 1 | `results/qualitative.log`, `derived` column |

Figures written to `results/`, all four used in the paper:

- `forest_plot_odds_ratios.pdf`
- `phishing_rates_combined_usenix.pdf`
- `clickcount_with_compromise_per_click_overlay.pdf`
- `self_reported_reasons_clicking_faceted.pdf`

## Known limitations

These are stated up front so evaluators do not have to discover them.

**The qualitative analysis is only partly reproducible here.** `Qualitative_coding.Rmd`
derives Cohen's κ = .881 and all seven open-text category frequencies from the coders'
labels in `Qualitative_coding.xlsx`, and asserts them rather than merely printing them.
The four **closed-format** counts in the same figure are still literals in the analysis
document on this branch, because this branch regenerates the submitted figure. They do
derive from the multi-select `reasons_click` item on the analysis sample, with no further
filter, and the camera-ready branch computes and asserts them.

**The first closed-format reason count is wrong in the submitted paper.** The figure gives
39 participants who said they thought the e-mail was legitimate. The data gives **40**; the
39 was a manual entry in the figure code, confirmed as an error by the analysis author on
2026-09-18. The other three counts (6 / 4 / 3) are correct and derive exactly. This branch
keeps 39 because its job is to regenerate the submitted figure; the camera-ready branch
reports the derived 40.

**The H2 model does not use the predictor the paper describes.** The submitted paper says
training intention is predicted "from the level of compromise in simulation 3", the
three-level measure H1 uses. The submitted code uses the binary click indicator
`clicked_sim1` on every path of the H2 model. This branch keeps it, because it is what
produced the submitted paper's H2 numbers; it is corrected in the camera-ready version.

**Some reported numbers are not computed here.** The power analysis and the four
gender-category counts are reported in the paper but are not part of this document.

**Mean age.** The paper reports 39.3 years (SD 10.4). That value was computed with a
recode that did not match the data's top age band, so the 29 oldest participants were
silently dropped. Corrected on this branch, the value is **39.8 years (SD 11.0)**. This
is the one number where the artifact deliberately disagrees with the paper, and it should
be fixed in the camera-ready text. Nothing else depends on it: `age_mean` is used only for
this descriptive statistic, while the models use the separate ordered `age` factor, which
was always correct.

**Output is part German, part English.** Some console labels and headings are in German.
They are cosmetic and do not affect any result.

## Data statement

`study_data_merged.xlsx` is survey and phishing-simulation log data from staff at a
single university. It is de-identified: direct identifiers and unused directory-derived
quasi-identifiers were removed before this artifact was assembled, and the institution is
not named anywhere in it.

`anonymisedEmail` is a 44-character pseudonym, retained because deduplication needs it. It
was generated through a cryptographic ceremony designed so that neither the researchers nor
the institution's IT security group, separately or together, can recover a participant's
actual email address from it.

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

`metadata.toml` is the artifact-evaluation submission metadata, produced by the S&P
packaging script (https://github.com/jelenamirkovic/artmeta). It is kept here so the
claims it registers stay version-controlled alongside the code that supports them; the
copy uploaded to HotCRP is the authoritative one. Re-running the packaging script in this
directory will pick this file up and offer each previous answer for amendment.

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
| `metadata.toml` | AE submission metadata, generated by the S&P packaging script |
| `LICENSE` | MIT, covering the code and the landing page |
| `LICENSE-DATA` | CC BY 4.0, covering the data, with a responsible-use note |
