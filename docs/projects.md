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
#TODO: STEP 3 (Energy-Delay simulated optimal curve)

## STEP 4: Energy-Delay optimal curve from theoretical model
#TODO: STEP 4 (Energy-Delay optimal curve from theoretical model)

## STEP 5: Theoretical model results verification
#TODO: STEP 5 (Theoretical model results verification)

---

# Project 02
#TODO: Project 02

---

# Project 03
#TODO: Project 03
