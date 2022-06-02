pragma circom 2.0.0;

include "vclmul_emulator.circom";
include "helper_functions.circom";

template GFMULInt()
{
    signal input a[2];
    signal input b[2];
    signal output res[2];

    var tmp[5][2];
    var XMMMASK[2] = [0x1, 0xc200000000000000];

    var i, j, k;

    component vclmul_emulator_1[4];
    
    for(i=0; i<4; i++)
    {
        vclmul_emulator_1[i] = VCLMULEmulator(i);
        for(j=0; j<2; j++)
        {
            vclmul_emulator_1[i].src1[j] <== a[j];
            vclmul_emulator_1[i].src2[j] <== b[j];
        }

        tmp[i+1] = vclmul_emulator_1[i].destination;
    }

    component multibit_xor_1[2];
    for(i=0; i<2; i++) multibit_xor_1[i] = MultibitXor(64);
    for(i=0; i<2; i++)
    {
        multibit_xor_1[i].a <== tmp[2][i];
        multibit_xor_1[i].b <== tmp[3][i];
        tmp[2][i] = multibit_xor_1[i].out;
    }

    tmp[3][0] = 0;
    tmp[3][1] = tmp[2][0];

    tmp[2][0] = tmp[2][1];
    tmp[2][1] = 0;

    component multibit_xor_2[2];
    for(i=0; i<2; i++) multibit_xor_2[i] = MultibitXor(64);
    for(i=0; i<2; i++)
    {
        multibit_xor_2[i].a <== tmp[1][i];
        multibit_xor_2[i].b <== tmp[3][i];
        tmp[1][i] = multibit_xor_2[i].out;
    }

    component multibit_xor_3[2];
    for(i=0; i<2; i++) multibit_xor_3[i] = MultibitXor(64);
    for(i=0; i<2; i++)
    {
        multibit_xor_3[i].a <== tmp[4][i];
        multibit_xor_3[i].b <== tmp[2][i];
        tmp[4][i] = multibit_xor_3[i].out;
    }

    component vclmul_emulator_2 = VCLMULEmulator(1);
    for(i=0; i<2; i++)
    {
        vclmul_emulator_2.src1[i] <== XMMMASK[i];
        vclmul_emulator_2.src2[i] <== tmp[1][i];
    }

    tmp[2] = vclmul_emulator_2.destination;

    var t1[4], t3[4];
    
    component num2bits_1[2];
    component bits2num_1[4];
    for(i=0; i<2; i++) num2bits_1[i] = Num2Bits(64);
    for(i=0; i<4; i++) bits2num_1[i] = Bits2Num(32);

    for(i=0; i<2; i++)
    {
        num2bits_1[i].in <== tmp[1][i];
        for(j=0; j<2; j++)
        {
            var index = i*2+j;
            for(k=0; k<32; k++) bits2num_1[index].in[k] <== num2bits_1[i].out[j*32+k];
            t1[index] = bits2num_1[index].out;
        }
    }

    t3[0] = t1[2];
    t3[1] = t1[3];
    t3[2] = t1[0];
    t3[3] = t1[1];

    component num2bits_2[4];
    component bits2num_2[2];
    for(i=0; i<4; i++) num2bits_2[i] = Num2Bits(32);
    for(i=0; i<2; i++) bits2num_2[i] = Bits2Num(64);

    for(i=0; i<2; i++)
    {
        for(j=0; j<2; j++)
        {
            var index = i*2+j;
            num2bits_2[index].in <== t3[index];
            for(k=0; k<32; k++) bits2num_2[i].in[j*32+k] <== num2bits_2[index].out[k];
        }
        tmp[3][i] = bits2num_2[i].out;
    }

    component multibit_xor_4[2];
    for(i=0; i<2; i++) multibit_xor_4[i] = MultibitXor(64);
    for(i=0; i<2; i++)
    {
        multibit_xor_4[i].a <== tmp[2][i];
        multibit_xor_4[i].b <== tmp[3][i];
        tmp[1][i] = multibit_xor_4[i].out;
    }

    ////////////////////////////////////////////////////////////////////

    component vclmul_emulator_3 = VCLMULEmulator(1);
    for(i=0; i<2; i++)
    {
        vclmul_emulator_3.src1[i] <== XMMMASK[i];
        vclmul_emulator_3.src2[i] <== tmp[1][i];
    }

    tmp[2] = vclmul_emulator_3.destination;
    
    component num2bits_3[2];
    component bits2num_3[4];
    for(i=0; i<2; i++) num2bits_3[i] = Num2Bits(64);
    for(i=0; i<4; i++) bits2num_3[i] = Bits2Num(32);

    for(i=0; i<2; i++)
    {
        num2bits_3[i].in <== tmp[1][i];
        for(j=0; j<2; j++)
        {
            var index = i*2+j;
            for(k=0; k<32; k++) bits2num_3[index].in[k] <== num2bits_3[i].out[j*32+k];
            t1[index] = bits2num_3[index].out;
        }
    }

    t3[0] = t1[2];
    t3[1] = t1[3];
    t3[2] = t1[0];
    t3[3] = t1[1];

    component num2bits_4[4];
    component bits2num_4[2];
    for(i=0; i<4; i++) num2bits_4[i] = Num2Bits(32);
    for(i=0; i<2; i++) bits2num_4[i] = Bits2Num(64);

    for(i=0; i<2; i++)
    {
        for(j=0; j<2; j++)
        {
            var index = i*2+j;
            num2bits_4[index].in <== t3[index];
            for(k=0; k<32; k++) bits2num_4[i].in[j*32+k] <== num2bits_4[index].out[k];
        }
        tmp[3][i] = bits2num_4[i].out;
    }

    component multibit_xor_5[2];
    for(i=0; i<2; i++) multibit_xor_5[i] = MultibitXor(64);
    for(i=0; i<2; i++)
    {
        multibit_xor_5[i].a <== tmp[2][i];
        multibit_xor_5[i].b <== tmp[3][i];
        tmp[1][i] = multibit_xor_5[i].out;
    }

    component multibit_xor_6[2];
    for(i=0; i<2; i++) multibit_xor_6[i] = MultibitXor(64);
    for(i=0; i<2; i++)
    {
        multibit_xor_6[i].a <== tmp[4][i];
        multibit_xor_6[i].b <== tmp[1][i];
        res[i] <== multibit_xor_6[i].out;
    }

    for(var i=0; i<2; i++) log(res[i]);
}