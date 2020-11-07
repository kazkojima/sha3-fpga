# An ECP5 SHA3 digest module using freecores/sha3 implementation

This is an SHA3 message digest module for a limited use.  Input size should be less than 568-bit.  For more large inputs, see the original [freecores/sha3 implementation](https://github.com/freecores/sha3).

The target FPGA is ECP5-85G and yosys/nextpnr-ecp5 open software developing system is assumed. The module is tested successfully on the real chip with 50Mhz clock.

sha3.v includes keccak implementation from freecores/sha3 which is imported as a submodule.  Although the original freecores/sha3 gives only 512-bit width digests, other widths can be handled with a few tiny modifications.

## Device utilisation

```
Info: 	       TRELLIS_SLICE:  2363/41820     5%
```
