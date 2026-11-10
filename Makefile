# StatusCore SC64 - build/test (requires Verilator >= 5.0)
.RECIPEPREFIX := >
VERILATOR ?= verilator
RTL   := rtl/sc64_pkg.sv rtl/sc64_alu.sv rtl/sc64_immgen.sv rtl/sc64_decoder.sv rtl/sc64_regfile.sv
TESTS := alu immgen decoder regfile
TBFLAGS := --binary --timing -Wall -Wno-fatal -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-INITIALDLY

.PHONY: all lint test clean

all: lint test

# Strict lint of the synthesizable RTL: any warning is an error.
lint:
> @for m in sc64_alu sc64_immgen sc64_decoder sc64_regfile; do \
>   echo "lint $$m"; \
>   $(VERILATOR) --lint-only -Wall --top-module $$m $(RTL) || exit 1; \
> done

test: $(addprefix test_,$(TESTS))

test_%: $(RTL) tb/tb_%.sv
> $(VERILATOR) $(TBFLAGS) --top-module tb_$* --Mdir build/$* $(RTL) tb/tb_$*.sv
> ./build/$*/Vtb_$*

clean:
> rm -rf build
