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

    var i, j, k, l;

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

    component num2bits_1[4][2];
    var tmp_bytes[5][4][32];
    for(i=0; i<4; i++)
    {
        for(j=0; j<2; j++)
        {
            num2bits_1[i][j] = Num2Bits(64);
            num2bits_1[i][j].in <== tmp[i+1][j];

            for(k=0; k<2; k++)
            {
                for(l=0; l<32; l++) tmp_bytes[i+1][j*2+k][l] = num2bits_1[i][j].out[k*32+l];
            }
        }
    }

    component xor_1[4][32];
    for(i=0; i<4; i++)
    {
        for(j=0; j<32; j++)
        {
            xor_1[i][j] = XOR();
            xor_1[i][j].a <== tmp_bytes[2][i][j];
            xor_1[i][j].b <== tmp_bytes[3][i][j];

            tmp_bytes[2][i][j] = xor_1[i][j].out;
        }
    }

    for(i=0; i<2; i++)
    {
        for(j=0; j<32; j++) tmp_bytes[3][i][j] = 0;
    }

    for(i=2; i<4; i++)
    {
        for(j=0; j<32; j++) tmp_bytes[3][i][j] = tmp_bytes[2][i-2][j];
    }

    for(i=0; i<2; i++)
    {
        for(j=0; j<32; j++) tmp_bytes[2][i][j] = tmp_bytes[2][i+2][j];
    }

    for(i=2; i<4; i++)
    {
        for(j=0; j<32; j++) tmp_bytes[2][i][j] = 0;
    }

    component xor_2[4][32];
    for(i=0; i<4; i++)
    {
        for(j=0; j<32; j++)
        {
            xor_2[i][j] = XOR();
            xor_2[i][j].a <== tmp_bytes[1][i][j];
            xor_2[i][j].b <== tmp_bytes[3][i][j];

            tmp_bytes[1][i][j] = xor_2[i][j].out;
        }
    }

    component xor_3[4][32];
    for(i=0; i<4; i++)
    {
        for(j=0; j<32; j++)
        {
            xor_3[i][j] = XOR();
            xor_3[i][j].a <== tmp_bytes[4][i][j];
            xor_3[i][j].b <== tmp_bytes[2][i][j];

            tmp_bytes[4][i][j] = xor_3[i][j].out;
        }
    }

    component bits2num_1[2];
    for(i=0; i<2; i++)
    {
        bits2num_1[i] = Bits2Num(64);
        for(j=0; j<2; j++)
        {
            for(k=0; k<32; k++)
            {
                bits2num_1[i].in[j*32+k] <== tmp_bytes[1][i*2+j][k];
            }
        }
        tmp[1][i] = bits2num_1[i].out;
    }

    component vclmul_emulator_2 = VCLMULEmulator(1);
    for(i=0; i<2; i++)
    {
        vclmul_emulator_2.src1[i] <== XMMMASK[i];
        vclmul_emulator_2.src2[i] <== tmp[1][i];
    }

    tmp[2] = vclmul_emulator_2.destination;

    component num2bits_2[2];
    for(i=0; i<2; i++)
    {
        num2bits_2[i] = Num2Bits(64);
        num2bits_2[i].in <== tmp[2][i];
        for(j=0; j<2; j++)
        {
            for(k=0; k<32; k++) tmp_bytes[2][i*2+j][k] = num2bits_2[i].out[j*32+k];
        }
    }

    tmp_bytes[3][0] = tmp_bytes[1][2];
    tmp_bytes[3][1] = tmp_bytes[1][3];
    tmp_bytes[3][2] = tmp_bytes[1][0];
    tmp_bytes[3][3] = tmp_bytes[1][1];

    component xor_4[4][32];
    for(i=0; i<4; i++)
    {
        for(j=0; j<32; j++)
        {
            xor_4[i][j] = XOR();
            xor_4[i][j].a <== tmp_bytes[2][i][j];
            xor_4[i][j].b <== tmp_bytes[3][i][j];

            tmp_bytes[1][i][j] = xor_4[i][j].out;
        }
    }

    component bits2num_2[2];
    for(i=0; i<2; i++)
    {
        bits2num_2[i] = Bits2Num(64);
        for(j=0; j<2; j++)
        {
            for(k=0; k<32; k++)
            {
                bits2num_2[i].in[j*32+k] <== tmp_bytes[1][i*2+j][k];
            }
        }
        tmp[1][i] = bits2num_2[i].out;
    }

    component vclmul_emulator_3 = VCLMULEmulator(1);
    for(i=0; i<2; i++)
    {
        vclmul_emulator_3.src1[i] <== XMMMASK[i];
        vclmul_emulator_3.src2[i] <== tmp[1][i];
    }

    tmp[2] = vclmul_emulator_3.destination;

    component num2bits_3[2];
    for(i=0; i<2; i++)
    {
        num2bits_3[i] = Num2Bits(64);
        num2bits_3[i].in <== tmp[2][i];
        for(j=0; j<2; j++)
        {
            for(k=0; k<32; k++) tmp_bytes[2][i*2+j][k] = num2bits_3[i].out[j*32+k];
        }
    }

    tmp_bytes[3][0] = tmp_bytes[1][2];
    tmp_bytes[3][1] = tmp_bytes[1][3];
    tmp_bytes[3][2] = tmp_bytes[1][0];
    tmp_bytes[3][3] = tmp_bytes[1][1];

    component xor_5[4][32];
    for(i=0; i<4; i++)
    {
        for(j=0; j<32; j++)
        {
            xor_5[i][j] = XOR();
            xor_5[i][j].a <== tmp_bytes[2][i][j];
            xor_5[i][j].b <== tmp_bytes[3][i][j];

            tmp_bytes[1][i][j] = xor_5[i][j].out;
        }
    }

    component xor_6[4][32];
    component bits2num_3[2];
    for(i=0; i<2; i++)
    {
        bits2num_3[i] = Bits2Num(64);
        for(j=0; j<2; j++)
        {
            for(k=0; k<32; k++)
            {
                xor_6[i*2+j][k] = XOR();
                xor_6[i*2+j][k].a <== tmp_bytes[1][i*2+j][k];
                xor_6[i*2+j][k].b <== tmp_bytes[4][i*2+j][k];

                bits2num_3[i].in[j*32+k] <== xor_6[i*2+j][k].out;
            }
        }
        res[i] <== bits2num_3[i].out;
    }
}