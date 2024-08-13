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


### Makefile
- `make verif1`
    - Run the code with #1 test case.
- `make verif2`
    - Run the code with #2 test case.
- `make verif3`
    - Run the code with #3 test case.
- `make real`
    - RUn the code with #4 test case.
 
### Tabel 1: The control signals

| I/O	| Signal | name |	Bit | width	| Description |
|:==:|:==:|:==:|:==:|:==:|:==:|
Input	clk	1	The clock signal
Input	rst_n	1	The reset signal, which is active low.
Input	in_valid	1	The input is valid when in_valid is high and will only high for one cycle.
Input	K	8	dimension K of the matrix (M,K), (K,N)
Input	M	8	dimension K of the matrix (M,K), (K,N)
Input	N	8	dimension K of the matrix (M,K), (K,N)
Output	busy	1	High when the design is busy. Pattern will check your answer when busy is low after every in_valid.


