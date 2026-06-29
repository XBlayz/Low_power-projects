# Project 01
Energy-Delay Optimization of a Three-Stage CMOS Buffer

## STEP 1: Minimum Inverter Sizing
I calculate the **minimum inverter size** ($w_{p,0}$) by measuring the _rise_ and _fall_ **delays** at different PMOS widths ($w_p$) and finding at which point the two are **equal**.

The evaluated _range_ is from `100nm` to `300nm` in steps of `10nm` and the _intersection point_ is determined by doing a **linear interpolation**. The final value is _rounded_ to the nearest `5nm` value related to the **minimum layout grid** of the technology (_planar `28nm-40nm`_).

From this step we determinate:
- **Minimum inverter size**: $w_{p,0}$
- **Delay of minimum-sized inverter**: $\tau_0$

## STEP 2: Model Calibration
For calibrating the **Energy-Delay** model, we need to extract the following parameters:
- $\gamma_E$: Ratio between the _drain capacitance_ and the _input capacitance_ ($\gamma_E = \frac{C_d}{C_{in}}$)
- $\gamma_D$: Parameter for **delay scaling** related to the _delay of minimum-sized inverter_ ($\gamma_D = \frac{S_{load}}{S} \frac{\tau_0}{\Delta t - \tau_0}$)
- $C_{in,0}$: **Input capacitance** of _minimum-sized inverter_

### Gamma Energy calculation & Minimum-sized Inverter Input Capacitance
For calculating $\gamma_E$, we need to measure the **drain capacitance** ($C_d$) and the **input capacitance** ($C_{in}$) of the _inverter_.

From this two values we obtain $\gamma_E$ using is _definition ratio_ ($\gamma_E = \frac{C_d}{C_{in}}$).

#### Drain Capacitance calculation
The **drain capacitance** is calculated by measuring the **energy** required for switching a _single inverter without any load_.

The **energy** is measured using the following formula:

$$E_d = \int_{t_1}^{t_2} V_{dd} \cdot I(t) dt$$

where $t_1$ is the _starting_ of the _falling edge_ of the **input** and $t_2$ is the _end_ of the _rising edge_ of the **output** (the _edge_ is defined as `99%` of the **steady state** value).
From the **energy** we calculate the **drain capacitance** using the following formula:

$$C_d = \frac{E_d}{V_{dd}^2}$$

This measurement is performed for different **inverter sizes** (`1` to `10` with a step of `0.25`) and then the final **drain capacitance** is _averaged_ from all the measurements (each value is normalized for the sizing $C_d' = C_d / S$).

#### Input Capacitance calculation
The **input capacitance** is calculated by measuring the **energy** required for switching a _dual stage inverter buffer_ with the second stage inverter used as a **load** for adding his **input capacitance** to the _first stage inverter_.

The **energy** is measured using the same formula used for the **drain capacitance**.

In this case the measured **capacitance** is actually $C_{meas} = C_{d,1} + C_{in,2}$, for isolating the **input capacitance** we need to subtract the **drain capacitance** of the first stage. This value is calculated at the _previous step_ (selecting the value related to the _minimum inverter size_).

This measurement is performed for different **inverter load sizes** (`1` to `10` with a step of `0.25`) and then the final **input capacitance** is _averaged_ from all the measurements (each value is normalized for the sizing $C_{in}' = C_{in} / S$).

Also, the **input capacitance** of the _minimum-sized inverter_ ($C_{in,0}$) is extracted from this step (selecting the value related to the _minimum inverter size_).

### Gamma Delay calculation
For calculating $\gamma_D$, we need to measure the **delay** of an _inverter_.

The **delay** is measured switching a _dual stage inverter buffer_ with the second stage inverter used as a **load**.

Using the definition formula ($\gamma_D = \frac{S_{load}}{S} \frac{\tau_0}{\Delta t - \tau_0}$) we calculate $\gamma_D$ for different **inverter load sizes** (`1` to `10` with a step of `0.25`). The final value is _averaged_ from all the measurements.

> _Note_: $\tau_0$ is determined during `STEP 1: Minimum Inverter Sizing`.

## STEP 3: Energy-Delay simulated optimal curve
For deriving the **empirical Pareto curve**, we need to explore the _design space_ defined by the scaling factors of the second and third inverter ($S_2$ and $S_3$) and identify the **envelope** of minimum energy points for each delay value.

The exploration is performed via a **Monte Carlo simulation** in _LTspice_, sweeping $S_2$ and $S_3$ as _random variables_ over a range covering both `low-power` and `high-performance` configurations, while keeping the final load fixed at `50x` the minimum inverter (as defined in the _design constraints_).

For each _run_, the **energy** dissipated by the buffer and the **total propagation delay** are measured, generating a _cloud of design points_ in the energy-delay plane. From this cloud, the **Pareto frontier** is extracted by selecting, for each delay bin, the point with _minimum energy_, discarding all _dominated_ points (i.e. points for which another configuration exists with both lower energy and lower delay).

> _Note_: the **energy** is measured using the same approach described in `STEP 2: Model Calibration` (integrating $V_{DD} \cdot I(t)$ over the switching transient), while the **delay** is the sum of the propagation delays of the _three stages_.

From this step we determinate:
- **Empirical Pareto curve**: the set of $(D, E)$ points constituting the _envelope_ of the Monte Carlo simulation, used as _reference_ for validating the theoretical model in `STEP 5`.

## STEP 4: Energy-Delay optimal curve from theoretical model
For deriving the **theoretical Pareto curve**, we use the **energy and delay models** calibrated in `STEP 2: Model Calibration`, applying the **sensitivity analysis methodology** through a _numerical optimization tool_.

The **delay model** for the three-stage buffer is expressed as:

$$D(S_2, S_3) = \tau_0 \left(1 + \frac{1}{\gamma_D} S_2\right) + \tau_0 \left(1 + \frac{1}{\gamma_D} \frac{S_3}{S_2}\right) + \tau_0 \left(1 + \frac{1}{\gamma_D} \frac{50}{S_3}\right)$$

The **energy model** for the three-stage buffer is expressed as:

$$E = V_{DD}^2 \left[\gamma_E C_{in,0} + S_2 C_{in,0} + \gamma_E S_2 C_{in,0} + S_3 C_{in,0} + \gamma_E S_3 C_{in,0} + C_L\right]$$

where $C_L$ is the **capacitive load** of the last stage ($50 \times C_{in,0}$).

The **optimization** is performed by _minimizing_ the dynamic **energy** dissipation subject to a fixed **delay constraint** ($D(S_2, S_3) = D_{target}$), repeating the procedure for an appropriate set of _delay constraints_ spanning the range of interest. For each constraint, a pair of optimal sizings $(S_2, S_3)$ is obtained.

> _Note_: the optimization is performed using a **constrained nonlinear solver** (e.g. _Python_ optimizer such as `scipy.optimize.minimize` with the `SLSQP` method), since the **delay constraint** is _nonlinear_ in $S_2$ and $S_3$.

From this step we determinate:
- **Theoretical Pareto curve**: the set of $(S_2, S_3)$ pairs minimizing energy for each delay constraint, together with the corresponding $(D, E)$ points computed via the _calibrated models_.

## STEP 5: Theoretical model results verification
For **validating** the theoretical model, each pair $(S_2, S_3)$ obtained in `STEP 4` is used to configure the _three-stage buffer_ in **LTspice**, simulating the _actual_ energy and delay for that specific sizing.

The set of $(D, E)$ points obtained from these simulations constitutes the **Pareto curve derived via sensitivity analysis**, which is then compared against the **empirical Pareto curve** derived in `STEP 3` to assess whether the two curves _substantially coincide_.

The comparison focuses on:
- **Convexity**: verifying that both curves exhibit the same _qualitative trend_ in the energy-delay trade-off.
- **Quantitative offset**: any systematic _deviation_ between the curves (e.g. the theoretical model underestimating the dissipated energy) is attributed to the _accuracy_ of the analytical model (in particular, the _approximations_ introduced by the linear $C_{in} \propto W$ and $C_d \propto W$ relations).

From this step we determinate:
- **Model validation**: confirmation that, despite possible _quantitative offsets_, the theoretical model correctly identifies the _optimal trade-offs_ between energy and delay, making it a _reliable tool_ for the **sensitivity analysis methodology**.

---

# Project 02
TODO: Project 02

---

# Project 03
TODO: Project 03
