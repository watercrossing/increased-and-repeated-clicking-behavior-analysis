#!/usr/bin/env bash
#
# One-command reproduction of the paper's results.
#
#   ./run_analysis.sh [image-tag]
#
# Builds nothing: run `docker build -t repeat-clicker .` first.
#
# Output goes to results/ : analysis.log with every result the analysis prints,
# sectioned by the part of the paper it supports; qualitative.log for the
# qualitative coding; the four figures used in the paper; and
# supplementary_plots.pdf with every plot the analysis draws. To get the knitted
# HTML documents instead, see the alternative invocation in README.md.

set -euo pipefail

IMAGE="${1:-repeat-clicker}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RMD="Repeat_clicker_analysis_5.Rmd"
QUAL_RMD="Qualitative_coding.Rmd"
OUT="$HERE/results"
PAPER_VERSION="submitted"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image '$IMAGE' not found. Build it first:" >&2
  echo "    docker build -t $IMAGE $HERE" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"
cp "$HERE/$RMD" "$HERE/study_data_merged.xlsx" \
   "$HERE/$QUAL_RMD" "$HERE/Qualitative_coding.xlsx" "$OUT/"

# The working directory must be writable: the figures land in it. We copy in
# rather than mounting the repository read-write so a run cannot modify the
# checked-in sources.
#
# --network none proves the image needs no network at analysis time.
#
# The code is not echoed: the log holds results only, and each section() banner
# in it marks the same place in the .Rmd. print.eval = TRUE is required, not
# cosmetic: the document relies on top-level auto-printing in many places and
# plain source() shows none of it. Plots not saved as a figure of their own
# would otherwise go to R's default Rplots.pdf; the explicit device names the
# file and gives the multi-panel diagnostics room.
docker run --rm --network none \
  -v "$OUT":/work -w /work \
  "$IMAGE" \
  Rscript -e "
    invisible(knitr::purl('$RMD', output = 'analysis.R', documentation = 0, quiet = TRUE))
    pdf('supplementary_plots.pdf', width = 11, height = 8.5)
    source('analysis.R', echo = FALSE, print.eval = TRUE)
    invisible(dev.off())
  " 2>&1 | tee "$OUT/analysis.raw.log"

# Put a short guide and a table of contents, with line numbers, in front of a
# log. The contents are read off the section banners the analysis printed.
#   with_contents <raw log> <final log> <guide text>
with_contents() {
  local raw="$1" log="$2" guide="$3" n_sections offset
  n_sections=$(grep -c '^### [0-9]*\. ' "$raw")
  offset=$(( $(printf '%s' "$guide" | wc -l) + 2 * n_sections + 2 ))
  {
    printf '%s' "$guide"
    awk -v off="$offset" '
      /^### [0-9]+\. / {
        n = NR; title = substr($0, 5)
        getline paper; sub(/^###    /, "", paper)
        printf "%6d  %s\n        %s\n", n + off, title, paper
      }' "$raw"
    printf '%80s\n\n' '' | tr ' ' '-'
    cat "$raw"
  } > "$log"
}

PAPER="Right Concept, Wrong Application? Psychological Effects in
Phishing Simulations Drive Training Intentions and Repeat Clicking (IEEE S&P 2027),
$PAPER_VERSION version."

with_contents "$OUT/analysis.raw.log" "$OUT/analysis.log" "Analysis log: $PAPER
Written by run_analysis.sh from $RMD.

How to read it
- Each numbered section opens with a banner naming the part of the paper it
  supports, or 'not reported' for supporting output the paper does not use.
- A line starting '>>> ' says which value below it a claim in the paper is taken
  from. Search for '>>> ' to step through every reported value in order.
- sim0, sim0.5, sim1 and sim2 are the paper's simulations 1, 2, 3 and 4.
- The R code is not repeated here. Each banner is printed by a section() call in
  $RMD, so searching the .Rmd for a section's title finds its code.
- Cohen's kappa and the open-text category counts are in qualitative.log.

Contents (line numbers in this file)
"

# The qualitative coding is a separate document because it reads a separate
# file. It asserts its published values rather than only printing them, so a
# mismatch fails the run instead of being left for the reader to notice.
docker run --rm --network none \
  -v "$OUT":/work -w /work \
  "$IMAGE" \
  Rscript -e "
    invisible(knitr::purl('$QUAL_RMD', output = 'qualitative.R', documentation = 0, quiet = TRUE))
    source('qualitative.R', echo = FALSE, print.eval = TRUE)
  " 2>&1 | tee "$OUT/qualitative.raw.log"

with_contents "$OUT/qualitative.raw.log" "$OUT/qualitative.log" "Qualitative coding log: $PAPER
Written by run_analysis.sh from $QUAL_RMD and Qualitative_coding.xlsx.

How to read it
- Laid out like analysis.log: each numbered section opens with a banner naming
  the part of the paper it supports, and a line starting '>>> ' says which value
  below it a claim in the paper is taken from.
- A line starting 'Check passed: ' is an assertion against the paper's value.
  A mismatch stops the run with an error instead.
- The R code is not repeated here. Searching $QUAL_RMD
  for a section's title finds its code.
- The four closed-format reasons in Figure 6 come from the survey data, not from
  the coding, and are in analysis.log.

Contents (line numbers in this file)
"

# Remove the copies so results/ holds only output.
rm -f "$OUT/$RMD" "$OUT/study_data_merged.xlsx" "$OUT/analysis.R" \
      "$OUT/$QUAL_RMD" "$OUT/Qualitative_coding.xlsx" "$OUT/qualitative.R" \
      "$OUT/analysis.raw.log" "$OUT/qualitative.raw.log"

echo
echo "Done. Output in results/:"
ls -1 "$OUT"
