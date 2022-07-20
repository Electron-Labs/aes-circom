// Copyright © 2022, Electron Labs
pragma circom 2.0.0;

include "mul.circom";

template VCLMULEmulator(imm) {
    signal input src1[2];
    signal input src2[2];
    signal output destination[2];

    component mul = Mul();

    if(imm == 0){
        mul.src1 <== src1[0];
        mul.src2 <== src2[0];
        destination[0] <== mul.out[0];
        destination[1] <== mul.out[1];
    }
    else if(imm == 1){
        mul.src1 <== src1[1];
        mul.src2 <== src2[0];
        destination[0] <== mul.out[0];
        destination[1] <== mul.out[1];
    }
    else if(imm == 2){
        mul.src1 <== src1[0];
        mul.src2 <== src2[1];
        destination[0] <== mul.out[0];
        destination[1] <== mul.out[1];
    }
    else if(imm == 3){
        mul.src1 <== src1[1];
        mul.src2 <== src2[1];
        destination[0] <== mul.out[0];
        destination[1] <== mul.out[1];
    }
}