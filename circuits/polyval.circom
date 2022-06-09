pragma circom 2.0.0;

include "gfmul_int.circom";
include "helper_functions.circom";

template POLYVAL(msg_len)
{
    signal input in[msg_len/8];
    signal input H[2];
    signal input T[2];
    signal output result[2];

    var current_res[2] = T, in_t[2];

    var i, j, k;
    var blocks = msg_len/16;

    component int_xor_1[blocks][2];
    component gfmul_int_1[blocks];
    for(i=0; i<blocks; i++)
    {
        for(j=0; j<2; j++) int_xor_1[i][j] = IntXor(64);
        gfmul_int_1[i] = GFMULInt();
    }
    
    if(blocks != 0)
    {
        for(i=0; i<blocks; i++)
        {
            in_t[0] = in[2*i];
            in_t[1] = in[2*i+1];

            for(j=0; j<2; j++)
            {
                int_xor_1[i][j].a <== current_res[j];
                int_xor_1[i][j].b <== in_t[j];

                current_res[j] = int_xor_1[i][j].out;
            }

            for(j=0; j<2; j++)
            {
                gfmul_int_1[i].a[j] <== current_res[j];
                gfmul_int_1[i].b[j] <== H[j];
            }

            current_res = gfmul_int_1[i].res;
        }
    }

    result[0] <== current_res[0];
    result[1] <== current_res[1];
}