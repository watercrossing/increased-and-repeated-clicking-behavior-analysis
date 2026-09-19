#!/usr/bin/env bash
#
# One-command reproduction of the paper's results.
#
#   ./run_analysis.sh [image-tag]
#
# Builds nothing: run `docker build -t repeat-clicker .` first.
#
# Output goes to results/ : plain-text logs of everything the two analysis
# documents printed, and the four figures used in the paper. To get the knitted
# HTML documents instead, see the alternative invocation in README.md.

set -euo pipefail

IMAGE="${1:-repeat-clicker}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RMD="Repeat_clicker_analysis_5.Rmd"
QUAL_RMD="Qualitative_coding.Rmd"
OUT="$HERE/results"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image '$IMAGE' not found. Build it first:" >&2
  echo "    docker build -t $IMAGE $HERE" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"
cp "$HERE/$RMD" "$HERE/study_data_merged.xlsx" \
   "$HERE/$QUAL_RMD" "$HERE/Qualitative_coding.xlsx" "$OUT/"

# The working directory must be writable: ggplot writes Rplots.pdf, and the
# figures and knitted HTML land alongside it. We copy in rather than mounting
# the repository read-write so a run cannot modify the checked-in sources.
#
# --network none proves the image needs no network at analysis time.
docker run --rm --network none \
  -v "$OUT":/work -w /work \
  "$IMAGE" \
  Rscript -e "
    knitr::purl('$RMD', output = 'analysis.R', documentation = 0)
    # print.eval = TRUE is required, not cosmetic: the document relies on
    # top-level auto-printing in many places and plain source() shows none of it.
    source('analysis.R', echo = TRUE, print.eval = TRUE, max.deparse.length = Inf)
  " 2>&1 | tee "$OUT/analysis.log"

# The qualitative coding is a separate document because it reads a separate
# file. It asserts its two published values rather than only printing them, so
# a mismatch fails the run instead of being left for the reader to notice.
docker run --rm --network none \
  -v "$OUT":/work -w /work \
  "$IMAGE" \
  Rscript -e "
    knitr::purl('$QUAL_RMD', output = 'qualitative.R', documentation = 0)
    source('qualitative.R', echo = TRUE, print.eval = TRUE, max.deparse.length = Inf)
  " 2>&1 | tee "$OUT/qualitative.log"

# Remove the copies so results/ holds only output.
rm -f "$OUT/$RMD" "$OUT/study_data_merged.xlsx" "$OUT/analysis.R" \
      "$OUT/$QUAL_RMD" "$OUT/Qualitative_coding.xlsx" "$OUT/qualitative.R"

echo
echo "Done. Output in results/:"
ls -1 "$OUT"
