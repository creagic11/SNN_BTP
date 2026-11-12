# Archived results

These results are kept for traceability. They are superseded or exploratory and are not used in the paper.

| Directory | Content | Reason for archiving |
| --- | --- | --- |
| `vivado_2024_1/` | First Vivado builds of the hidden layer (27 October 2026) | Superseded by `power_saif_v5/`. The board top level observed only 12 of 32 output lanes, so synthesis removed most of BASE; weights were stored as ROMs and trimmed to 6 bits; per-column weight enables were absent. |
| `power_saif/` | First gate-level power estimates of the hidden layer (28 October 2026) | Same defects as `vivado_2024_1/`; superseded by `power_saif_v5/`. |
| `power_saif_v5/` | Corrected hidden-layer builds and gate-level power (28 October 2026) | Superseded by the whole-network runs in `results/power_l1/` and `results/power_l2/` (output layer and classifier on chip, retrained networks). The method is unchanged. |
| `ablations/abl_*`, `ablations/abl2_*`, `ablations/abl3_*` | Training ablations of the recurrent adaptive LIF network on the Spiking Heidelberg Digits | Exploratory; summarised in `notes/development_log.md` (26–27 October 2026). |
| `ablations/dabl_*` | Training ablations of the axonal-delay network | Exploratory; summarised in `notes/development_log.md`. |
| `ablations/probe_rec_u` | Membrane-potential probe of the recurrent network | Diagnostic run. |

The training logs of these runs are in `results/logs/`. The scripts that produced the ablations
(`scripts/ablate_*.sh`) write to `results/<tag>`; their outputs were moved here afterwards.
