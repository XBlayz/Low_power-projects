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

### Project 03: Dynamic Power Optimization of a Synthesized RTL Circuit
The objective of this project is the application of Registering and Reordering low-power techniques to reduce the dynamic power dissipation of a synthesized RTL circuit, replicating the reference design and methodology of Christian Pitingolo (*Progetto Low-Power - 3*, December 2025).

#### Reference Circuit
The reference circuit performs a 32-bit addition between two of four available operands (`A`, `B`, `C`, `D`), selected via two multiplexers (`MUX_CD` and `MUX_AB`) sharing a common selection signal `Z`. `Z` is the output of a `parity_check` block (XOR tree) fed by the 8-bit sum of two selection signals `sel1` and `sel2`, computed by an 8-bit Ripple Carry Adder (`RCA8`). When the sum `sel1 + sel2` is odd (`Z = 1`), operands `A` and `C` are selected and summed by a 32-bit Ripple Carry Adder (`RCA32`); when even (`Z = 0`), operands `B` and `D` are selected instead. The result is registered on a 33-bit output register (`Z_reg`).

#### Design Constraints
1. The RTL is described in `VHDL` and targets an FPGA device via `Vivado` (synthesis + implementation)
2. The functional behavior of the reference circuit must be preserved by every optimized variant (bit-exact addition result and selection logic)
3. The clock constraint is fixed per comparison campaign (`10ns` for the standard campaign, a tighter constraint for the high-performance campaign)
4. Dynamic power is analyzed excluding I/O contributions, using the Vivado Power Report (`Logic`, `Signals`, `Clock` breakdown)
#### Tasks to Perform
*(Based on personal considerations, replicating the reference methodology and simulations)*

1. Implement the baseline reference circuit in `VHDL` and verify it with a Behavioral simulation testbench (functional correctness of the `A+C` / `B+D` selection logic).
2. Run Post-implementation (post-P&R) simulation on the baseline to characterize the glitch behavior on the multiplexer selection signal, and extract the baseline resource usage, timing (WNS, `fmax`), and dynamic power report.
3. Apply the **Registering** technique: insert an intermediate pipeline stage for the data path and the multiplexer selection signal (`sel_1_2`), removing the combinational glitch at the mux select input. Re-run Behavioral and Post-implementation simulations and extract the corresponding resource usage, timing, and dynamic power report.
4. Apply the **Reordering** technique: restructure the topology using two dedicated 32-bit adders (`Adder32AC`, `Adder32BD`) computing both `A+C` and `B+D` in parallel, selecting the correct sum a posteriori via a result multiplexer (`MUX_SUM`) driven by the `parity_check` output. Re-run Post-implementation simulation and extract the corresponding resource usage, timing, and dynamic power report.
5. Apply the **combined** Registering + Reordering architecture (pipelined dual-adder topology with registered selection signal). Re-run Post-implementation simulation and extract the corresponding resource usage, timing, and dynamic power report.
6. Compare all four configurations (Baseline, Registering, Reordering, Registering & Reordering) under both the standard clock constraint and a tighter, high-performance clock constraint, and validate the results against the reference figures (LUT/FF count, WNS, `fmax`, Logic/Signals/Clock power).
