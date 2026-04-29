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
  - `src`: contains the **LTspice simulation** files (one subfolder for each _project_)
  - `libs`: contains the _LTspice model files_ (do not need to be used in the **python code**)
