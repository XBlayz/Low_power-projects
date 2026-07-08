# Repo structure

## Libraries
- `numpy`: used for **numerical operations**
- `pandas`: used for **data manipulation** and _analysis_
- `PyLTSpice`: used for **running LTSpice simulation** and _extracting data_
- `seaborn`: used for **data visualization**

## Folders
- `notebooks`: contains **Jupyter Notebooks** for all the _projects_
  - `output`: contains the output files generated during the code execution (for each _project_ create a subfolder)
    - `figs`: contains the saved **figures**
    - `sims`: contains the **simulation output** files
- `res`: contains all the necessary files for all the _projects_
  - `src`: contains the **LTspice simulation** files and **Vivado sorce files** (one subfolder for each _project_)
    - `vivado_constrs`: _Vivado constraints_ files
    - `vivado_srcs`: _VHDL source_ files for top-level designs
    - `vivado_tbs`: _VHDL testbench_ files
  - `libs`: contains the _LTspice model files_ and **Vivado sorce files** (do not need to be used in the **python code**)
    - `vivado_comps`: _VHDL source_ files for components used in the top-level designs
- `scripts`: contains **Tcl scripts**
