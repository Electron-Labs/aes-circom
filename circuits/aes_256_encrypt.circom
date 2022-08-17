pragma circom 2.0.0;

include "aes_emulation_tables.circom";
include "aes_emulation.circom";
include "helper_functions.circom";

template AES256Encrypt()
{
    signal input in[4];
    signal input ks[60];
    signal output out[4];

    var ks_index = 0;
    var s[4][32], t[4][32];
    
    var i,j,k,l;
    
    component num2bits_1[4][2];
    component xor_1[4][32];

    for(i=0; i<4; i++)
    {
        num2bits_1[i][0] = Num2Bits(32);
        num2bits_1[i][0].in <== in[i];

        num2bits_1[i][1] = Num2Bits(32);
        num2bits_1[i][1].in <== ks[i+ks_index];

        for(j=0; j<32; j++)
        {
            xor_1[i][j] = XOR();
            xor_1[i][j].a <== num2bits_1[i][0].out[j];
            xor_1[i][j].b <== num2bits_1[i][1].out[j];

            s[i][j] = xor_1[i][j].out;
        }
    }
    
    ks_index += 4;

    component xor_2[13][4][3][32];
    component bits2num_1[13][4][4];
    component num2bits_2[13][4][4];
    component xor_3[13][4][32];
    component num2bits_3[13][4];
    component emulated_aesenc_enc_selector[13][4][4];

    for(i=0; i<13; i++)
    {
        for(j=0; j<4; j++)
        {
            for(k=0; k<4; k++)
            {
                bits2num_1[i][j][k] = Bits2Num(8);
                num2bits_2[i][j][k] = Num2Bits(32);
                var s_tmp[32] = s[(j+k)%4];
                
                for(l=0; l<8; l++) bits2num_1[i][j][k].in[l] <== s_tmp[k*8+l];

                // num2bits_2[i][j][k].in <-- emulated_aesenc_enc_table(k, bits2num_1[i][j][k].out);
                emulated_aesenc_enc_selector[i][j][k] = IndexSelector(256);

                for(var iter = 0; iter<256; iter++){
                    emulated_aesenc_enc_selector[i][j][k].in[iter] <== emulated_aesenc_enc_table(k, iter);
                }

                emulated_aesenc_enc_selector[i][j][k].index <== bits2num_1[i][j][k].out;

                num2bits_2[i][j][k].in <== emulated_aesenc_enc_selector[i][j][k].out;

                if(k==0)
                {
                    for(l=0; l<32; l++)
                    {
                        xor_2[i][j][k][l] = XOR();
                        xor_2[i][j][k][l].a <== num2bits_2[i][j][k].out[l];
                    }
                }
                else if(k<3)
                {
                    for(l=0; l<32; l++)
                    {
                        xor_2[i][j][k-1][l].b <== num2bits_2[i][j][k].out[l];

                        xor_2[i][j][k][l] = XOR();
                        xor_2[i][j][k][l].a <== xor_2[i][j][k-1][l].out;
                    }
                }
                else
                {
                    for(l=0; l<32; l++)
                    {
                        xor_2[i][j][k-1][l].b <== num2bits_2[i][j][k].out[l];

                        xor_3[i][j][l] = XOR();
                        xor_3[i][j][l].a <== xor_2[i][j][k-1][l].out;
                    }
                }
            }
        }

        for(j=0; j<4; j++)
        {
            num2bits_3[i][j] = Num2Bits(32);
            num2bits_3[i][j].in <== ks[j+ks_index];

            for(l=0; l<32; l++)
            {
                xor_3[i][j][l].b <== num2bits_3[i][j].out[l];
                s[j][l] = xor_3[i][j][l].out;
            }
        }
        ks_index += 4;
    }

    component bits2num_2[16];
    var s_bytes[16];

    for(i=0; i<4; i++)
    {
        for(j=0; j<4; j++)
        {
            bits2num_2[i*4+j] = Bits2Num(8);
            for(k=0; k<8; k++) bits2num_2[i*4+j].in[k] <== s[i][j*8+k];
            s_bytes[i*4+j] = bits2num_2[i*4+j].out;
        }
    }

    component row_shifting = EmulatedAesencRowShifting();
    component sub_bytes = EmulatedAesencSubstituteBytes();
    for(i=0; i<16; i++) row_shifting.in[i] <== s_bytes[i];
    for(i=0; i<16; i++) sub_bytes.in[i] <== row_shifting.out[i];

    component num2bits_5[16];

    for(i=0; i<4; i++)
    {
        for(j=0; j<4; j++)
        {
            num2bits_5[i*4+j] = Num2Bits(8);
            num2bits_5[i*4+j].in <== sub_bytes.out[i*4+j];
            for(k=0; k<8; k++) s[i][j*8+k] = num2bits_5[i*4+j].out[k];
        }
    }

    component num2bits_6[4];
    component xor_4[4][32];

    for(i=0; i<4; i++)
    {
        num2bits_6[i] = Num2Bits(32);
        num2bits_6[i].in <== ks[i+ks_index];
        for(j=0; j<32; j++)
        {
            xor_4[i][j] = XOR();
            xor_4[i][j].a <== s[i][j];
            xor_4[i][j].b <== num2bits_6[i].out[j];

            s[i][j] = xor_4[i][j].out;
        }
    }

    component bits2num_3[4];
    for(i=0; i<4; i++)
    {
        bits2num_3[i] = Bits2Num(32);
        for(j=0; j<32; j++) bits2num_3[i].in[j] <== s[i][j];
        out[i] <== bits2num_3[i].out;
    }
}


