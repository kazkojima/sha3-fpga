
ARCH=ecp5
DEVICE=um5g-85k
PACKAGE=CABGA381
PINCONSTRAINTS=ecp5-evn.lpf
BITSTREAM=top_ecp5.svf

#QUIET=-q
#QUIET=--verbose --debug

.PHONY: all prog sim clean

.PRECIOUS: %.json %.asc %.bin %.rpt %.txtcfg

FREECORES_SHA3_DIRS := freecores-sha3/low_throughput_core/rtl
FREECORES_SHA3_RTL := rconst.v round.v f_permutation.v
FREECORES_SHA3_SRC := $(foreach f,$(FREECORES_SHA3_RTL),$(FREECORES_SHA3_DIRS)/$(f))

all: $(BITSTREAM) $(TIMINGREPORT)

prog: $(BITSTREAM)
	openocd -f ecp5-evn.openocd.conf -c "transport select jtag; init; svf progress quiet $<; exit"

clean:
	-rm -f *.json
	-rm -f *.asc
	-rm -f *.bin
	-rm -f *.rpt
	-rm -f *.txtcfg
	-rm -f *.svf
	-rm -f *_tb.test
	-rm -f *.vvp
	-rm -f *.vcd
	-rm -f *.out
	-rm -f *~


top_$(ARCH).json: top.v $(FREECORES_SHA3_SRC)

tb.vvp: tb.v $(FREECORES_SHA3_SRC)
	iverilog -s testbench -o $@ $^

sim: tb.vvp
	vvp -N $<
	gtkwave testbench.vcd

%_ecp5.json: %.v
	yosys -Q $(QUIET) -p 'synth_ecp5 -nomux -top $(subst .v,,$<) -json $@' $^

%_ecp5.txtcfg: %_ecp5.json
	nextpnr-ecp5 $(QUIET) --ignore-loops --placer sa --$(DEVICE) --package $(PACKAGE) --lpf $(PINCONSTRAINTS) --json $< --textcfg $@

%_ecp5.svf: %_ecp5.txtcfg
	ecppack --svf $@ $<
