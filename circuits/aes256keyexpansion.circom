pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "encryption/aes_emulation_tables.circom";

template AES256KeyExpansion()
{
    signal input key[32];
    signal output w[60];

    var rcon[10] = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36];

    var Nk = 8;
    var Nb = 4;
    var Nr = 14;
    var ks[60][32];
    var key_bits[32][8];

    var i, j, k;

    component num2bits_1[32];
    for(i=0; i<32; i++)
    {
        num2bits_1[i] = Num2Bits(8);
        num2bits_1[i].in <== key[i];
        key_bits[i] = num2bits_1[i].out;
    }

    i = 0;
    while(i<Nk)
    {
        for(j=0; j<4; j++)
        {
            for(k=0; k<8; k++) ks[i][j*8+k] = key_bits[i*4+j][k];
        }
        i++;
    }

    component xor_1[60][32];
    component bits2num_1[60][4];
    component num2bits_2[60][5];
    component xor_2[60][8];


    while(i<(Nb*(Nr+1)))
    {
        var tmp[32];
        tmp = ks[i-1];

        if(i%Nk == 0)
        {
            bits2num_1[i][0] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][0].in[j] <== tmp[j];
            num2bits_2[i][0] = Num2Bits(8);
            num2bits_2[i][0].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][0].out);

            bits2num_1[i][1] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][1].in[j] <== tmp[j+8];
            num2bits_2[i][1] = Num2Bits(8);
            num2bits_2[i][1].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][1].out);

            bits2num_1[i][2] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][2].in[j] <== tmp[j+16];
            num2bits_2[i][2] = Num2Bits(8);
            num2bits_2[i][2].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][2].out);

            bits2num_1[i][3] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][3].in[j] <== tmp[j+24];
            num2bits_2[i][3] = Num2Bits(8);
            num2bits_2[i][3].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][3].out);

            for(j=0; j<8; j++) tmp[j+24] = num2bits_2[i][0].out[j];
            for(j=0; j<8; j++) tmp[j] = num2bits_2[i][1].out[j];
            for(j=0; j<8; j++) tmp[j+8] = num2bits_2[i][2].out[j];
            for(j=0; j<8; j++) tmp[j+16] = num2bits_2[i][3].out[j];

            num2bits_2[i][4] = Num2Bits(8);
            num2bits_2[i][4].in <== rcon[i/Nk-1];

            for(j=0; j<8; j++)
            {
                xor_2[i][j] = XOR();
                xor_2[i][j].a <== tmp[j];
                xor_2[i][j].b <== num2bits_2[i][4].out[j];

                tmp[j] = xor_2[i][j].out;
            }
        }
        else if(i%Nk == 4)
        {
            bits2num_1[i][0] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][0].in[j] <== tmp[j];
            num2bits_2[i][0] = Num2Bits(8);
            num2bits_2[i][0].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][0].out);

            bits2num_1[i][1] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][1].in[j] <== tmp[j+8];
            num2bits_2[i][1] = Num2Bits(8);
            num2bits_2[i][1].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][1].out);

            bits2num_1[i][2] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][2].in[j] <== tmp[j+16];
            num2bits_2[i][2] = Num2Bits(8);
            num2bits_2[i][2].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][2].out);

            bits2num_1[i][3] = Bits2Num(8);
            for(j=0; j<8; j++) bits2num_1[i][3].in[j] <== tmp[j+24];
            num2bits_2[i][3] = Num2Bits(8);
            num2bits_2[i][3].in <-- emulated_aesenc_rijndael_sbox(bits2num_1[i][3].out);

            for(j=0; j<8; j++) tmp[j] = num2bits_2[i][0].out[j];
            for(j=0; j<8; j++) tmp[j+8] = num2bits_2[i][1].out[j];
            for(j=0; j<8; j++) tmp[j+16] = num2bits_2[i][2].out[j];
            for(j=0; j<8; j++) tmp[j+24] = num2bits_2[i][3].out[j];
        }
        
        for(j=0; j<32; j++)
        {
            xor_1[i][j] = XOR();
            xor_1[i][j].a <== ks[i-Nk][j];
            xor_1[i][j].b <== tmp[j];

            ks[i][j] = xor_1[i][j].out;
        }
        i++;
    }

    component bits2num_2[60];
    for(i=0; i<60; i++)
    {
        bits2num_2[i] = Bits2Num(32);
        for(j=0; j<32; j++) bits2num_2[i].in[j] <== ks[i][j];
        w[i] <== bits2num_2[i].out;
    }
}
