---
lang: en
---

# Low power Projects
Low power digital systems design projects

## Projects presentation
### Project 01: Energy-Delay Optimization of a Three-Stage CMOS Buffer
The objective of this project is the application of the sensitivity analysis methodology to optimize the design of a three-stage CMOS buffer.

#### Design Constraints
1. The buffer must have `3` stages
2. The first stage is a minimum-sized inverter
3. The last stage has a capacitive load of an inverter sized `50x` the minimum inverter
4. The independent variables that can be used for optimization are the aspect ratios of the second and third inverters relative to the dimensions of the minimum inverter

#### Tasks to Perform
*(Based on personal considerations and following simulations performed with a specific simulation setup)*

1. Determine the sizing of the minimum inverter.
2. Calibrate the buffer energy and delay model (as seen in class) for the technology used. Specifically, find the following constants:
   * `gamma_delay`
   * `gamma_energy`
   * `tau0`
   * Input capacitance of the minimum inverter
3. Considering the aspect ratio of the second and third inverters (relative to the minimum inverter dimensions) as variables that can be set in the optimization process, derive the **Energy-Delay Pareto curve** empirically. This is done by deriving the envelope of the design points in the Energy-Delay space obtained via Monte Carlo simulation.
4. Derive the same Pareto curve using the **sensitivity analysis methodology**:
Using a numerical optimization tool and the energy and delay models mentioned above, derive the aspect ratios that minimize dynamic energy dissipation for an appropriate set of delay constraints. In this way, for each delay constraint analyzed, a pair of sizings will be obtained, e.g., $(W_1, W_2)$.
5. For each of the pairs found in the previous step, simulate the buffer with **LTSPICE** to derive the actual corresponding design points in the energy-delay space. The set of these points constitutes the optimal Pareto curve derived via sensitivity analysis. Verify that this curve substantially coincides with the curve derived empirically.

### Project 02: ...
TODO

### Project 03: ...
TODO
