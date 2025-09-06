// Boilerplate code
module spi_peripheral (
    input wire a,    // input a
    input wire b,    // input b
    output wire y    // output y
);

    assign y = a & b; // continuous assignment

endmodule