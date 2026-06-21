# Green Hydrogen Microgrid — Reinforcement Learning Control (MATLAB / Simscape)

A DC islanded microgrid that produces **green hydrogen** by powering an electrolyzer
from a solar array and a battery energy-storage system. The plant is modeled in
**MATLAB / Simulink / Simscape** (multi-domain: electrical, thermal-liquid and
thermal-gas), and is used here as the **environment for reinforcement-learning (RL)
based supervisory control** of power dispatch and hydrogen production.

The Simscape plant is built on the MathWorks *Green Hydrogen Microgrid* example
(© The MathWorks, Inc.). This repository extends it toward learned, RL-based
energy management.

---

## System overview

```
            Solar Array (PV)            Battery Energy Storage
            peak ~210 kW                 50 Ah, 240 V nominal
                  |                              |
                  +-------------DC Bus-----------+
                                |
                      DC/DC Converter (η lookup)
                                |
                          Electrolyzer
                    100 cells, 3 electrode pairs
                                |
                          H2 + O2 + heat
                                |
                       Hydrogen Tank (1 m3, 273.15 K)
```

- **Solar array** — supplies the primary energy; a 24-hour irradiance/power profile
  (peak ≈ 210 kW) is replayed over the simulated horizon.
- **Battery energy storage** — buffers the solar surplus/deficit so the electrolyzer
  can keep running through low-irradiance periods.
- **Electrolyzer** — converts electrical power into hydrogen; modeled with
  temperature-dependent efficiency, membrane area/resistance, and an electric
  heating element.
- **Hydrogen tank** — accumulates produced H₂ (mass tracked as `mH2`).
- **Supervisory controller** — decides how to split power between solar and storage
  and how hard to drive the electrolyzer. **This is the component RL targets.**

The model simulates green-hydrogen production over a **7-day period**, either from
solar alone or from solar combined with the energy-storage system.

---

## Repository layout

The repository ships the microgrid in **two self-contained variants**. Each variant
folder is runnable on its own — open it as the MATLAB current folder and run the
example script.

```
GreenHydrogenMicrogrid/
├── README.md                 ← this file
├── docs/
│   └── GreenHydrogenMicrogrid_Explainer.pdf   ← detailed walkthrough of the model and RL setup
├── baseline-no-RL/           ← rule-based supervisory control (reference plant)
└── rl/                       ← same plant wired as an RL environment
```

### `baseline-no-RL/` — rule-based reference

| File | Description |
|------|-------------|
| `GreenHydrogenMicrogrid.slx` | Simulink/Simscape model of the microgrid (plant + **rule-based** lookup-table control). |
| `GreenHydrogenMicrogridExample.m` | Top-level script — opens the model and plots results. |
| `GreenHydrogenMicrogridData.m` | All model parameters (solar profile, electrolyzer, battery, hydrogen properties, control sample time). |
| `GreenHydrogenMicrogridPlotResults.m` | Runs the simulation (if needed) and plots power, battery SOC and produced H₂. |
| `simlogNeedsUpdate.m` | Helper that decides whether the model must be re-simulated. |

### `rl/` — reinforcement-learning variant

Same plant and parameter/plot scripts as the baseline, plus the RL pieces:

| File | Description |
|------|-------------|
| `GreenHydrogenMicrogrid.slx` | Microgrid model with the rule-based supervisor replaced by an **RL Agent block** (`Energy storage/RL Agent`). |
| `RL_agent.m` | Sets up the RL environment — defines observation/action specs, builds the `rlSimulinkEnv`, and creates a PPO agent. |
| `ReinforcementLearningDesignerSession.mat` | Saved Reinforcement Learning Designer session for the agent. |

> Simulink generates `*.slxc` cache files and a `slprj/` build folder when a model is
> opened/compiled. These are auto-generated and are intentionally **not** committed.

---

## Requirements

- **MATLAB** R2024a or later (model last saved with R2026a)
- **Simulink**
- **Simscape** (multi-domain physical modeling)
- **Simscape Electrical** and **Simscape Fluids** (electrical + thermal-liquid/gas domains)
- **Reinforcement Learning Toolbox** — required for the RL-control work; not needed
  to run the baseline plant simulation
- *(optional)* **Deep Learning Toolbox** — for neural-network policies/critics

---

## Getting started

1. Open MATLAB and set the variant folder as the current directory —
   `baseline-no-RL/` for the rule-based plant, or `rl/` for the RL environment.
2. Load the parameters:
   ```matlab
   GreenHydrogenMicrogridData
   ```
3. Run the full example (opens the model, simulates, and plots):
   ```matlab
   GreenHydrogenMicrogridExample
   ```
   or simulate directly:
   ```matlab
   sim('GreenHydrogenMicrogrid')
   GreenHydrogenMicrogridPlotResults
   ```
4. *(RL variant only)* set up the RL environment and PPO agent:
   ```matlab
   RL_agent
   ```

The results figure shows three stacked plots over time (hours):
power (electrolyzer / solar / storage), **battery state of charge (SOC)**, and
**produced hydrogen mass (kg)**.

---

## Key parameters

Defined in `GreenHydrogenMicrogridData.m`:

| Group | Parameter | Value |
|-------|-----------|-------|
| Control | Sample time `Ts` | 10 s |
| Solar | Peak power | ≈ 210 kW (24 h profile) |
| Battery | Nominal capacity `Battery.Qn` | 50 000 |
| Battery | Nominal voltage `Battery.Un` | 240 V |
| Battery | Series resistance `Battery.Rs` | 0.2 Ω |
| Electrolyzer | Cells `Electrolyzer.N_cell` | 100 |
| Electrolyzer | Electrode pairs `Electrolyzer.Np_electrodes` | 3 |
| Electrolyzer | Efficiency range | 0.55 – 0.90 (temperature-dependent) |
| Electrolyzer | Resistance | 0.25 Ω |
| Hydrogen tank | Volume `H2_Tank.Volume` | 1 m³ (100×100×100 cm) |
| Hydrogen tank | Storage temperature | 273.15 K |

The baseline supervisory logic is encoded as lookup tables in `Operation_Ref`
(electrolyzer current vs. available solar current) and `Converter`
(output current vs. efficiency).

---

## Reinforcement-learning control

The baseline controller is **rule-based** (lookup tables). The goal of this project
is to replace/augment that supervisor with an **RL agent** that learns an
energy-management policy maximizing hydrogen yield while respecting battery limits.

A proposed formulation (to be implemented in the model and a training script):

- **Observation** — solar power, battery SOC, electrolyzer power/temperature,
  hydrogen produced, and time-of-day features.
- **Action** — power split between solar and storage and the electrolyzer power
  setpoint (continuous), at the `Ts = 10 s` control rate.
- **Reward** — hydrogen produced, penalized for SOC limit violations, deep
  discharge, and inefficient electrolyzer operation.
- **Agents** — continuous-action methods (e.g. DDPG / TD3 / PPO) from the
  Reinforcement Learning Toolbox, training against the Simscape plant as the
  environment.

> **Status:** the Simscape plant and rule-based baseline are in place (`baseline-no-RL/`).
> The `rl/` variant adds the **RL Agent block** to the model and an environment-setup
> script (`RL_agent.m`) that builds the `rlSimulinkEnv` and a PPO agent. Reward shaping
> and a full training/benchmark run are the active work items — see the roadmap below.
> This section documents intended design, not a shipped policy.

---

## Roadmap

- [x] Wrap the Simscape model as an RL environment (RL Agent block + `rlSimulinkEnv`)
- [ ] Define observation/reward signals and reward shaping with SOC/temperature constraints
- [ ] Train and benchmark the RL policy against the rule-based baseline
- [ ] Report hydrogen yield, SOC behavior, and energy efficiency comparisons

---

## License & attribution

The microgrid plant model and example scripts are derived from the MathWorks
*Green Hydrogen Microgrid* example and remain
**© 2018–2023 The MathWorks, Inc.** Refer to your MATLAB/Simulink license for the
terms governing the original example files. RL-control additions in this repository
are provided for research and educational use.
