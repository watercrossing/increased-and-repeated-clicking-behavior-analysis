# Data provenance

How `study_data_merged.xlsx` was collected, by whom, where and when. The authoritative
account is the paper.

## Setting

A single large public university with over 18,000 employees, described in the paper as a
research-intensive organisation comprising academic, administrative, technical and
business operational staff. The institution's IT Security Group (ISG) had been running
phishing simulations roughly once a year as part of an established security awareness
programme, independently of this research.

## The four phishing simulations

The dataset covers the organisation's four most recent simulations at the time of
collection:

| Simulation | Date | Platform |
|---|---|---|
| 1 | March 2023 | CybSafe |
| 2 | July 2024 | CybSafe |
| 3 | February 2025 | Microsoft Defender |
| 4 | May 2025 | Microsoft Defender |

The spacing is uneven because it follows the organisation's own practice rather than a
research schedule.

The platform change between simulations 2 and 3 matters for the data. Exposure to
simulations 1–2 is evidenced by "opened" events; simulations 3–4 instead require a
successful "delivery" event together with either a "read" or a "deleted" event. This is
why the repeat-clicking subset (N = 115) is smaller than it would otherwise be: it
excludes participants who did receive and open all four simulations but cannot be
confirmed to the same standard.

The per-simulation columns reflect this split — `sim0_*` and `sim0.5_*` carry the CybSafe
fields for simulations 1 and 2, `sim1_*` and `sim2_*` the Microsoft Defender fields for
simulations 3 and 4.

## The survey

Three days after simulation 3, all employees who had received that simulation
were invited to an online survey, framed as feedback on the institution's
cybersecurity measures. Participation was voluntary and informed consent was obtained
from respondents, who could optionally enter a prize draw.

The instrument collected demographics and seven standardised scales, all on 7-point
Likert items: locus of control, risk perception, negative emotional responses, training
acceptance, perceived self-efficacy, optimism bias, and training intention. Open-ended
questions at the end captured self-reported reasons for having fallen for a simulation.
Full items are in the paper's Appendix B.

1,625 responses were recorded. The analysis sample of 986 is reached by excluding 138
duplicate respondents, 419 who failed at least one of three attention checks, and 82 who
showed no reliable indication of having seen simulations 3 and 4. All three steps are
performed by `Repeat_clicker_analysis_5.Rmd` and their counts are printed when it runs.
The three counts reconcile with the analysis sample: 1625 − 138 − 419 − 82 = 986.

## Linkage

Simulation logs and survey responses were linked by the ISG, not by the research team,
using a per-participant anonymous key. The researchers received only the linked,
pseudonymised result. `anonymisedEmail` is that key: a 44-character pseudonym, retained
here because the deduplication step needs it.

The key was generated through a cryptographic ceremony designed so that neither the
researchers nor the ISG, separately or together, can recover a participant's actual email
address from it. The ceremony was reviewed as part of the study's ethics approval.

## De-identification

The published dataset is de-identified: direct identifiers and unused directory-derived
quasi-identifiers were removed before publication, and the institution is not named
anywhere in it. The free-text survey responses are retained, having been screened for
identifying information; `Qualitative_coding.xlsx` carries the same responses and was
screened to the same standard.

None of this can have changed a reported result: no removed column is referenced anywhere
in `Repeat_clicker_analysis_5.Rmd`, and that was checked rather than assumed.

The internal files this was derived from are not in this deposit, and neither are the
scripts that derived them, since they are of no use without their inputs.

## Preregistration

Hypotheses and analysis plan were preregistered before data collection:
https://aspredicted.org/dv8e5t.pdf
