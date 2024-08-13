# AAML2023 4x4 TPU

### Brief introduction 
This is a 4x4 TPU IP using Weight Stationary (WS) technology.To accelerates matrix operations over a wide range of lengths and widths.

### Directory Structure
```bash
.
├── data_generator.py
├── Makefile
├── README.md
├── RTL
│   ├── global_buffer.v
│   └── TPU.v
└── TESTBENCH
    ├── PATTERN.v
    └── TESTBENCH.v
```

- `RTL`: The source code of your design
- `TESTBENCH`: The testbench to test your design.
- `data_generator.py`: The generator to generate the test case.


## Makefile
- `make verif1`
    - Run the code with #1 test case.
- `make verif2`
    - Run the code with #2 test case.
- `make verif3`
    - Run the code with #3 test case.
- `make real`
    - RUn the code with #4 test case.


