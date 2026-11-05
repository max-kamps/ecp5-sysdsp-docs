# ECP5 sysDSP Internals Documentation

## Documents

- Lattice ECP5 and ECP5-5G Family Data Sheet (`FPGA-DS-02012-3.4`)
    - Contains a general overview of the DSP block, which makes the rest easier to understand
- Lattice ECP5 and ECP5-5G sysDSP User Guide (`FPGA-TN-02205-1.3`)
- Lattice ECP3 sysDSP Usage Guide (`FPGA-TN-02193-1.4`)
    - Contains some information that was left out of the ECP5 documentation, as well extra diagrams
- Lattice Diamond 3.14 FPGA Libraries Reference Guide
    - Contains extra documentation for some config attributes and ports of primitives
- `lscc/diamond/3.14/cae_library/synthesis/verilog/ecp5um.v`
    - Contains the full list of ports, attributes (with default values), as well as a few comments
- Lattice Diamond Clarity Designer
    - Can open the generated `.v` files to see how some ports are used

## Overview

Each DSP block contains two DSP slices. Each slice contains:

- Either 1× ALU54 or 2× ALU24
    - ALU54:
        - 54-bit accumulator
        - 54-bit ternary adder
            - Operation: `A ± B ± C`
            - operands can be external or routed internally from the accumulator
            - operands can be dynamically signed or unsigned
            - 2× 36-bit external inputs, and 1× 54-bit external input
        - Logic unit
            - Operations: `AND`, `OR`, `NAND`, `NOR`, `XOR`, `XNOR`
            - operands can be external or routed internally from the accumulator
            - 1× 36-bit external input, and 1× 54-bit external input
        - Flag outputs
            - Accumulator overflow
            - Accumulator underflow
            - Either accumulator overflow or underflow
            - Equal to zero
            - with configurable 0/1 mask:
                - Equal to zero (masked)
                - Equal to one (masked)
            - with configurable pattern mask and configurable or dynamic pattern:
                - Equal to pattern (masked)
                - Equal to inverted pattern (masked)
        - TODO Rounding
        - TODO Cascade Mach Register
        - TODO Shift out
        - TODO input muxes (A, B, C)
    - ALU24:
        - 24-bit accumulator
        - 24-bit ternary adder
            - Operation: `A ± B + C` ?
            - operands can be external or routed internally from the accumulator
            - operands can be dynamically signed or unsigned
            - 2× 18-bit external inputs, and 1× 24-bit external input
        - Flag outputs
            - Accumulator overflow
            - Accumulator underflow
            - Either accumulator overflow or underflow
            - Equal to zero
            - with configurable 0/1 mask:
                - Equal to zero (masked)
                - Equal to one (masked)
            - with configurable pattern mask and configurable or dynamic pattern:
                - Equal to pattern (masked)
                - Equal to inverted pattern (masked)
- 2× 18×18 multiplier, which can each be split into 2× 9×9 multipliers
    - optional input registers (optionally shift register)
    - optional pipeline register
    - optional output register (required if input registers are used)
    - operands can be dynamically signed or unsigned
- 2× 18-bit pre-adders, which can each be split into 2× 9-bit pre-adders

The ALU and Multipliers have a feature known as Highspeed Operation. This feature was removed from
all documentation, and I have not been able to find an old version that still describes it.
Presumably it was removed because it was found to be faulty, or perhaps because software support
was never implemented? I am not sure.

## PRADD18A detailed description

TODO

## PRADD9A detailed description

TODO

## MULT18X18C detailed description

- Input Signals:
    - `CE[3:0]`, `CLK[3:0]`, `RST[3:0]`
        - Clock enables, clocks, and resets
        - Which register uses which clock, clock enable, and reset is configurable
        - Whether all resets are synchronous or asynchronous is configurable
    - `{A,B}[17:0]`
        - Parallel input operands
    - `SRI{A,B}[17:0]`
        - Shift register input operands (hardwired to the adjacent MULT's `SRO{A,B}` output)
    - `SOURCE{A,B}`
        - Take operands from parallel input or shift register input?
        - `0` = parallel input, `1` = shift register input
    - `SIGNED{A,B}`
        - Are the operands signed or unsigned?
        - `0` = unsigned, `1` = signed
- Output Signals:
    - `RO{A,B}[17:0]`
        - Registered value of the parallel input
    - `SRO{A,B}[17:0]`
        - Registered value of the shift input (hardwired to the adjacent MULT's `SRI{A,B}` input)
    - `P[35:0]`
        - Product output
    - `SIGNEDP`
        - Is the product signed or unsigned?
        - `0` = unsigned, `1` = signed
- Configuration Attributes:
    - `REG_{INPUT{A,B},PIPELINE,OUTPUT}_CLK: "NONE" | "CLK{0-3}" = "NONE"`
        - Which clock to use for the register (or none)
    - `REG_{INPUT{A,B},PIPELINE,OUTPUT}_CE: "CE{0-3}" = "CE0"`
        - Which clock enable to use for the register
    - `REG_{INPUT{A,B},PIPELINE,OUTPUT}_RST: "RST{0-3}" = "RST0"`
        - Which reset to use for the register
    - `RESETMODE: "SYNC" | "ASYNC" = "SYNC"`
        - Whether all resets are synchronous or asynchronous
    - `GSR: "ENABLED" | "DISABLED" = "ENABLED"`
        - Whether to respond to the global reset signal from the `GSR` / `SGSR` primitive
    - `CAS_MATCH_REG: "FALSE" | "TRUE" = "FALSE"`
        - TODO "Cascade match register option"
    - `MULT_BYPASS: "DISABLED" | "ENABLED" = "DISABLED"`
        - TODO "Multiplier bypass option"
        - Inconsistent docs, "cae_library/synthesis/verilog/ecp5um.v" indicates this defaults to
          `"DISABLED"`, but "Diamond 3.14 FPGA Libraries Reference Guide" indicates this defaults to
          `"ENABLED"`.
        - Not sure, but this seems to forward inputs from `{A,B}` directly to `P` and `RO{A,B}`
          without performing a multiplication. `A` maps to the lower 18 bits of `P`, and `B` maps to
          the upper 18 bits of `P`.
        - Used for implementing 2-input 54-bit adders, although I don't quite understand the ALU
          setup for this. Bits which don't fit into the 36-bit `P = AB` are put into the ALU's C
          input... investigate further. (Clarity "adder_tree" generator)

## MULT9X9C detailed description

TODO

## ALU54A detailed description

- Input signals:
    - `CE[3:0]`, `CLK[3:0]`, `RST[3:0]`
        - Clock enables, clocks, and resets
        - Which register uses which clock, clock enable, and reset is configurable
        - Whether all resets are synchronous or asynchronous is configurable
    - `{A,B}[35:0]`
        - TODO Parallel input operands from unregistered multiplier output?
        - This is used to generate `{A,B}_ALU` for the ALU?
        - Clarity seems to connect this to multiplier `RO{A,B}`
            - `A[17:0]` <-> `MUL0.ROA`, `A[35:18]` <-> `MUL0.ROB`
            - `B[17:0]` <-> `MUL1.ROA`, `B[35:18]` <-> `MUL1.ROB`
    - `M{A,B}[35:0]`
        - TODO Parallel input operands from unregistered multiplier output?
        - This is used to generate `MULT{A,B}` for the ALU?
        - Clarity seems to connect this to multiplier's `P`
            - `MA[35:0]` <-> `MUL0.P`, `MB[35:0]` <-> `MUL1.P`
    - `SIGNED{A,B}`
        - Are the operands signed or unsigned?
        - `0` = unsigned, `1` = signed
    - `C[53:0]`
        - "Carry Input" or `C` operand. Used in a variety of ways for different operations
    - `CIN[53:0]`
        - "Cascade Input", hardwired to the `COUT` of an adjacent ALU54
        - Can be disconnected to disable?
        - TODO can this be wired to the `R` output of another ALU54, since the `COUT` output is not
          exposed as a port on the primitive?
    - `SIGNEDCIN`
        - TODO Is the CIN(?) input signed or unsigned?
        - `0` = unsigned, `1` = signed
    - `OP[10:0]`
        - TODO "`P[17:0]` has an independent multiplexer to bypass or not bypass the `COUT[17:0]` register. This is required to support 36*36 multiplication mode."
        - TODO "A 54-bit ALU does not always feed 54 bits from A, B and C. Sometimes it will select only 36b, as seen in Arithmetic Modes."
        - TODO intermediate signals:
            - `Cr` = `C[53:0]` registered
            - `ALUfeedback` = `R[53:0]` registered
            - TODO "`Cra` is generated from `Cr` by sign extending `Ar35` (on `Cr(17:0)`), and `Br35` (on `Cr(44:27)`)"
            - TODO "`Ara` is generated from the registered input of `A` (`AR`) sign extended to 36 bits"
            - TODO "`Bra` is generated from the registered input of `B` (`BR`) sign extended to 36 bits"
        - `OP[10:7]` = "Opcode"
            - TODO verify, this table is from ECP3
            - `0100` = `R = Amux + Bmux + Cmux`
            - `0101` = `R = Amux - Bmux + Cmux`
            - `0110` = `R = Amux + Bmux - Cmux`
            - `0111` = `R = Amux - Bmux - Cmux`
            - `1100` = `R = Bmux XNOR Cmux`
            - `1110` = `R = Bmux XOR Cmux`
            - `0000` = `R = Bmux NAND Cmux`
            - `1000` = `R = Bmux AND Cmux`
            - `0011` = `R = Bmux OR Cmux`
            - `1011` = `R = Bmux NOR Cmux`
            - TODO test undocumented opcodes
        - `OP[6:4]` = "CMuxsel"
            - `000` = `Cmux = 0`
            - `001` = `Cmux = CIN >> 18` TODO arithmetic or logical shift? Depend on SIGNEDCIN?
            - `010` = `Cmux = CIN`
            - `011` = `Cmux = C_ALU = sign_extend54(Cr)` TODO what's `Cr`?
            - `100` = `Cmux = A_ALU` TODO what's `A_ALU`?
            - `101` = `Cmux = ALUfeedback` TODO what's `ALUfeedback`?
            - `110` = `Cmux = RNDtoPN` Constant for rounding TODO formula for `RNDtoPN`?
            - `111` = `Cmux = RNDtoPNM1` Constant for rounding TODO formula for `RNDtoPNM1`?
        - `OP[3:2]` = "BMuxsel"
            - `00` = `Bmux = MULTB << 18`
            - `01` = `Bmux = extend54(MULTB)` sign or zero extended based on `SIGNEDB`
            - `10` = `Bmux = B_ALU = {Cra[44:27],Bra}` TODO what's `Cra` and `Bra`?
            - `11` = `Bmux = 0`
        - `OP[1:0]` = "AMuxsel"
            - `00` = `Amux = ALUfeedback` TODO what's `ALUfeedback`?
            - `01` = `Amux = extend54(MULTA)` sign or zero extended based on `SIGNEDA`
            - `10` = `Amux = A_ALU = {Cra[17:0],Ara}` TODO what's `Cra` and `Ara`?
            - `11` = `Amux = 0`
- Output signals:
    - `R[53:0]`
        - Parallel output result
    - `SIGNEDR`
        - Is the result signed or unsigned?
    - Result flags: (in equations, `_d` indicates the signal is unregistered)
        - `EQZ`
            - Is the result equal to zero?
            - `EQZ = not(bitwise_or(R)))`
        - `EQZM`
            - Is the result masked with the `MASK01` equal to zero?
            - `EQZM = bitwise_and(not(R) or MASK01)`
        - `EQOM`
            - Is the result masked with the `MASK01` equal to one?
            - `EQOM = bitwise_and(R or MASK01)`
        - `EQPAT`
            - Is the result masked with the `MASKPAT` equal to the `MCPAT`?
            - `EQPAT = bitwise_and(not(R xor MCPAT) or MASKPAT)`
        - `EQPATB`
            - Is the result masked with the `MASKPAT` equal to the inverted `MCPAT`?
            - `EQPATB = bitwise_and((R xor MCPAT) or MASKPAT)`
        - `OVER`
            - Did the result overflow?
            - `OVER = EQZM and not(EQOM_d or EQZM_d)`
        - `UNDER`
            - Did the result underflow?
            - `UNDER = EQOM and not(EQOM_d or EQZM_d)`
        - `OVERUNDER`
            - Did the result overflow or underflow?
            - `OVERUNDER = OVER or UNDER`
- Configuration Attributes:
    - `REG_{INPUTC{0,1},OUTPUT{0,1},FLAG}_CLK: "NONE" | "CLK{0-3}" = "NONE"`
        - Which clock to use for the C register (or none)
        - `INPUTC0` refers to `C[26:0]`, and `INPUTC1` refers to `C[53:27]`
        - TODO does the same apply to `OUTPUT{0,1}`?
    - `REG_{INPUTC{0,1},OUTPUT{0,1},FLAG}_CE: "CE{0-3}" = "CE0"`
        - Which clock enable to use for the C register
        - `INPUTC0` refers to `C[26:0]`, and `INPUTC1` refers to `C[53:27]`
        - TODO does the same apply to `OUTPUT{0,1}`?
    - `REG_{INPUTC{0,1},OUTPUT{0,1},FLAG}_RST: "RST{0-3}" = "RST0"`
        - Which reset to use for the C register
        - `INPUTC0` refers to `C[26:0]`, and `INPUTC1` refers to `C[53:27]`
        - TODO does the same apply to `OUTPUT{0,1}`?
    - TODO `REG_OPCODEOP0_0_CLK = "NONE";"`
        - TODO "Input reg of OPCODE `oper[0]`"
    - TODO `REG_OPCODEOP0_0_CE = "CE0";"`
        - TODO "Input reg of OPCODE `oper[3:0]`"
    - TODO `REG_OPCODEOP0_0_RST = "RST0";"`
        - TODO "Input reg of OPCODE `oper[3:0]`"
    - TODO `REG_OPCODEOP1_0_CLK = "NONE";"`
        - TODO "Input reg of OPCODE `oper[3:1]`"
    - TODO `REG_OPCODEOP0_1_CLK = "NONE";"`
        - TODO "Pipeline reg of OPCODE `oper[0]`"
    - TODO `REG_OPCODEOP0_1_CE = "CE0";"`
        - TODO "Pipeline reg of OPCODE `oper[3:0]`"
    - TODO `REG_OPCODEOP0_1_RST = "RST0";"`
        - TODO "Pipeline reg of OPCODE `oper[3:0]`"
    - TODO `REG_OPCODEOP1_1_CLK = "NONE";"`
        - TODO "Pipeline reg of OPCODE `oper[3:1]`"
    - TODO `REG_OPCODEIN_0_CLK = "NONE";"`
        - TODO "Input reg of OPCODE `InA[1:0]`, `InB[1:0]` and `InC[2:0]`"
    - TODO `REG_OPCODEIN_0_CE = "CE0";"`
        - TODO "Input reg of OPCODE `InA[1:0]`, `InB[1:0]` and `InC[2:0]`"
    - TODO `REG_OPCODEIN_0_RST = "RST0";"`
        - TODO "Input reg of OPCODE `InA[1:0]`, `InB[1:0]` and `InC[2:0]`"
    - TODO `REG_OPCODEIN_1_CLK = "NONE";"`
        - TODO "Pipeline reg of OPCODE `InA[1:0]`, `InB[1:0]` and `InC[2:0]`"
    - TODO `REG_OPCODEIN_1_CE = "CE0";"`
        - TODO "Pipeline reg of OPCODE `InA[1:0]`, `InB[1:0]` and `InC[2:0]`"
    - TODO `REG_OPCODEIN_1_RST = "RST0";"`
        - TODO "Pipeline reg of OPCODE `InA[1:0]`, `InB[1:0]` and `InC[2:0]`"
    - TODO `MCPAT_SOURCE = "STATIC";`
    - TODO `MASKPAT_SOURCE = "STATIC";`
    - `MASK01 = "0x00000000000000"`
    - `MCPAT = "0x00000000000000"`
    - `MASKPAT = "0x00000000000000"`
    - `RNDPAT = "0x00000000000000"`
    - `RESETMODE: "SYNC" | "ASYNC" = "SYNC"`
        - Whether all resets are synchronous or asynchronous
    - `GSR: "ENABLED" | "DISABLED" = "ENABLED"`
        - Whether to respond to the global reset signal from the `GSR` / `SGSR` primitive
    - TODO `MULT9_MODE = "DISABLED";`
    - TODO `FORCE_ZERO_BARREL_SHIFT = "DISABLED";`
    - TODO `LEGACY = "DISABLED"`
        - TODO "Sets OVERUNDER which is used to support LatticeECP2 legacy overflow"

## ALU24A detailed description

TODO
