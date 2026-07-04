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

### Project 02: Noise Margin Analysis of a 6T SRAM Cell
The objective of this project is the design and stability characterization of a 6T SRAM cell, evaluating its robustness against process variation through Static Noise Margin (SNM) analysis.

#### Design Constraints
1. The cell must use the standard `6T` topology: two cross-coupled CMOS inverters plus two NMOS access transistors
2. The supply voltage for the nominal sizing is `1V`
3. The access and pull-up transistors are sized at the technology's minimum width (`W_min`); the pull-down width is the free sizing variable
4. The sizing must satisfy `W_pdn > W_ax > W_pu` to guarantee both READ (`CR > 1`) and WRITE (`PR < 1`) robustness

#### Tasks to Perform
*(Based on personal considerations and following simulations performed with a specific simulation setup)*

1. Size the pull-down transistor via the graphical butterfly-curve method, targeting a READ SNM of `150mV` in HOLD and READ conditions.
2. Validate the graphical extraction against the **Seevinck method**, which computes SNM directly from an LTspice `.dc` sweep via a coordinate rotation, removing the need for external post-processing.
3. Assess **inter-die** process variation: run a Monte Carlo analysis with a threshold-voltage mismatch shared by every transistor, sweeping VDD and tabulating leakage power, HSNM, and RSNM statistics at each step.
4. Assess **intra-die** process variation: repeat the Monte Carlo analysis with an independent threshold-voltage mismatch per transistor, to capture the effect of local device mismatch on cell symmetry.
5. Compare the inter-die and intra-die results, quantifying the SNM degradation and the shift in Data Retention Voltage (DRV) distribution caused by local mismatch.

### Project 03: ...
TODO
