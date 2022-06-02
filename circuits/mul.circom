pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "rightshift.circom";
include "leftshift.circom";
include "xor2.circom";

template Mul() {
    signal input src1;
    signal input src2;
    signal output out[2];
    var dst[2];
    dst[0] = 0;
    dst[1] = 0;

    component num2bits1[64];
    component num2bits2[64];
    component num2bits3[64];
    component num2bits4[64];
    component num2bits5[64];
    component num2bits6[64];
    component num2bits7[64];
    component equality1[64];
    component equality2[64];
    component xor1[64];
    component xor2[64];
    component mux1[64];
    component mux2[64];
    component rightshift1[64];
    component rightshift2[64];
    component bits2num1[64];
    component bits2num2[64];
    component leftshift1[64];
    component bits2num3[64];
    component bits2num4[64];

    for(var iter=0; iter<64; iter++)
	{
        num2bits1[iter] = Num2Bits(64);
        num2bits1[iter].in <== src2;

        num2bits2[iter] = Num2Bits(64);
        num2bits2[iter].in <== src1;

        num2bits3[iter] = Num2Bits(64);
        num2bits3[iter].in <== dst[1];

        equality1[iter] = IsEqual();
        equality1[iter].in[0] <== 1;
        equality1[iter].in[1] <== num2bits1[iter].out[iter];//63-
        xor1[iter] = Xor2(64);
        for(var i=0; i<64; i++){
            xor1[iter].a[i] <== num2bits2[iter].out[i];
            xor1[iter].b[i] <== num2bits3[iter].out[i];
        }

        bits2num1[iter] = Bits2Num(64);
        for(var i=0; i<64; i++){
            bits2num1[iter].in[i] <== xor1[iter].out[i];
        }

        // dst[1] = bits2num1[iter].out;//(equality1[iter].out * bits2num1[iter].out) + ((1-equality1[iter].out)*(dst[1]));
        mux1[iter] = Mux1();
        mux1[iter].c[0] <== dst[1];
        mux1[iter].c[1] <== bits2num1[iter].out;
        mux1[iter].s <== equality1[iter].out;

        dst[1] = mux1[iter].out;

        num2bits4[iter] = Num2Bits(64);
        num2bits4[iter].in <== dst[0];

        rightshift1[iter] = RightShift(64, 1);
        for(var i = 0; i<64; i++){
            rightshift1[iter].in[i] <== num2bits4[iter].out[i]; 
        }

        num2bits5[iter] = Num2Bits(64);
        num2bits5[iter].in <== dst[1];

        equality2[iter] = IsEqual();
        equality2[iter].in[0] <== 1;
        equality2[iter].in[1] <== num2bits5[iter].out[0];

        

        // calc 1<<63
        num2bits6[iter] = Num2Bits(64);
        num2bits6[iter].in <== 1;

        leftshift1[iter] = LeftShift(64, 63);

        for(var i=0 ;i<64; i++){
            leftshift1[iter].in[i] <== num2bits6[iter].out[i];
        }

        xor2[iter] = Xor2(64);
        for(var i = 0; i<64; i++){
            xor2[iter].a[i] <== rightshift1[iter].out[i];
            xor2[iter].b[i] <== leftshift1[iter].out[i];
        }

        bits2num2[iter] = Bits2Num(64);
        for(var i = 0; i<64; i++){
            bits2num2[iter].in[i] <== xor2[iter].out[i];
        }

        bits2num4[iter] = Bits2Num(64);
        for(var i=0; i<64; i++){
            bits2num4[iter].in[i] <== rightshift1[iter].out[i];
        }

        mux2[iter] = Mux1();
        mux2[iter].c[0] <== bits2num4[iter].out;
        mux2[iter].c[1] <== bits2num2[iter].out;
        mux2[iter].s <== equality2[iter].out;
        
        dst[0] = mux2[iter].out;

        num2bits7[iter] = Num2Bits(64);
        num2bits7[iter].in <== dst[1];

        rightshift2[iter] = RightShift(64,1);
        for(var i=0; i<64; i++){
            rightshift2[iter].in[i] <== num2bits7[iter].out[i];
        }

        bits2num3[iter] = Bits2Num(64);
        for(var i=0; i<64; i++){
            bits2num3[iter].in[i] <== rightshift2[iter].out[i];
        }
        dst[1] = bits2num3[iter].out;
		// if(extreactBit(src2,i) == 1) dst[1]^=src1;
		
		// //Shift the result
		// dst[0]>>=1;
		// if(extreactBit(dst[1],0) == 1) dst[0]^=(((uint64_t)1)<<63);
		// dst[1]>>=1;
	}
    out[0] <== dst[0];
    out[1] <== dst[1];
}