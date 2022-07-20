// Copyright © 2022, Electron Labs
pragma circom 2.0.0;

include "aes_256_key_expansion.circom";
include "aes_256_encrypt.circom";
include "aes_256_ctr.circom";
include "polyval.circom";
include "helper_functions.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template GCM_SIV_DEC_2_Keys(aad_len, msg_len)
{
    signal input K1[32];
    signal input N[16];
    signal input AAD[aad_len];
    signal input CIPHERTEXT[msg_len+16];

    signal output MSG[msg_len];
    signal output success;

    var i, j, k;

    var MSG_t[msg_len];
    var CT[msg_len];
    for(i=0; i<msg_len; i++) CT[i] = CIPHERTEXT[i];
    var TAG[16];
    for(i=0; i<16; i++) TAG[i] = CIPHERTEXT[msg_len+i];
    var ks[60];
    var _N[4];
    var _T[12];
    var Record_Hash_Key[2];
    var Record_Enc_Key_64[4];
    var T[2] = [0, 0];
    var new_TAG[2];
    var CTR[2];
    var LENBLK[2];

    LENBLK[0] = aad_len*8;
    LENBLK[1] = msg_len*8;

    var TAG_64_1[2];
    component typecast_1 = Typecast(16, 8, 64);
    for(i=0; i<16; i++) typecast_1.in[i] <== TAG[i];
    TAG_64_1 = typecast_1.out;

    CTR[0] = TAG_64_1[0];
    CTR[1] = TAG_64_1[1];

    var CTR_8[16];
    component typecast_2 = Typecast(2, 64, 8);
    for(i=0; i<2; i++) typecast_2.in[i] <== CTR[i];
    CTR_8 = typecast_2.out;

    component int_or_1 = IntOr(8);
    int_or_1.a <== CTR_8[15];
    int_or_1.b <== 128;
    CTR_8[15] = int_or_1.out;

    component key_expansion_1 = AES256KeyExpansion();
    for(i=0; i<32; i++) key_expansion_1.key[i] <== K1[i];
    ks = key_expansion_1.w;

    var N_32[4];
    component typecast_3 = Typecast(16, 8, 32);
    for(i=0; i<16; i++) typecast_3.in[i] <== N[i];
    N_32 = typecast_3.out;
    _N[1] = N_32[0];
    _N[2] = N_32[1];
    _N[3] = N_32[2];

    component aes_256_encrypt_1[6];
    component typecast_4[6];
    for(i=0; i<6; i++)
    {
        aes_256_encrypt_1[i] = AES256Encrypt();
        typecast_4[i] = Typecast(4, 32, 64);
    }

    for(i=0; i<6; i++) 
    {
        _N[0] = i;
        var _T_32[4];

        for(j=0; j<4; j++) aes_256_encrypt_1[i].in[j] <== _N[j];
        for(j=0; j<60; j++) aes_256_encrypt_1[i].ks[j] <== ks[j];
        _T_32 = aes_256_encrypt_1[i].out;

        for(j=0; j<4; j++) typecast_4[i].in[j] <== _T_32[j];
        _T[2*i] = typecast_4[i].out[0];
        _T[2*i+1] = typecast_4[i].out[1];
    }

    Record_Hash_Key[0] = _T[0];
    Record_Hash_Key[1] = _T[2];
    Record_Enc_Key_64[0] = _T[4];
    Record_Enc_Key_64[1] = _T[6];
    Record_Enc_Key_64[2] = _T[8];
    Record_Enc_Key_64[3] = _T[10];

    var Record_Enc_Key[32];
    component typecast_5 = Typecast(4, 64, 8);
    for(i=0; i<4; i++) typecast_5.in[i] <== Record_Enc_Key_64[i];
    Record_Enc_Key = typecast_5.out;

    component key_expansion_2 = AES256KeyExpansion();
    for(i=0; i<32; i++) key_expansion_2.key[i] <== Record_Enc_Key[i];
    ks = key_expansion_2.w;

    var CTR_32[4];
    component typecast_6 = Typecast(16, 8, 32);
    for(i=0; i<16; i++) typecast_6.in[i] <== CTR_8[i];
    CTR_32 = typecast_6.out;

    component aes_256_ctr = AES256CTR(msg_len);
    for(i=0; i<msg_len; i++) aes_256_ctr.in[i] <== CT[i];
    for(i=0; i<4; i++) aes_256_ctr.ctr[i] <== CTR_32[i];
    for(i=0; i<60; i++) aes_256_ctr.ks[i] <== ks[i];
    MSG_t = aes_256_ctr.out;

    component typecast_7 = Typecast(aad_len, 8, 64);
    component polyval_1 = POLYVAL(aad_len);
    if(aad_len != 0)
    {
        var AAD_64[aad_len/8];
        
        for(i=0; i<aad_len; i++) typecast_7.in[i] <== AAD[i];
        AAD_64 = typecast_7.out;

        
        for(i=0; i<aad_len/8; i++) polyval_1.in[i] <== AAD_64[i];
        for(i=0; i<2; i++)
        {
            polyval_1.H[i] <== Record_Hash_Key[i];
            polyval_1.T[i] <== T[i];
        }

        T = polyval_1.result;
    }

    var MSG_64[msg_len/8];
    component typecast_8 = Typecast(msg_len, 8, 64);
    for(i=0; i<msg_len; i++) typecast_8.in[i] <== MSG_t[i];
    MSG_64 = typecast_8.out;

    component polyval_2 = POLYVAL(msg_len);
    for(i=0; i<msg_len/8; i++) polyval_2.in[i] <== MSG_64[i];
    for(i=0; i<2; i++)
    {
        polyval_2.H[i] <== Record_Hash_Key[i];
        polyval_2.T[i] <== T[i];
    }

    T = polyval_2.result;

    component polyval_3 = POLYVAL(16);
    for(i=0; i<2; i++) polyval_3.in[i] <== LENBLK[i];
    for(i=0; i<2; i++)
    {
        polyval_3.H[i] <== Record_Hash_Key[i];
        polyval_3.T[i] <== T[i];
    }

    T = polyval_3.result;

    var N_64[2];
    component typecast_9 = Typecast(16, 8, 64);
    for(i=0; i<16; i++) typecast_9.in[i] <== N[i];
    N_64 = typecast_9.out;

    component int_xor_1[2];
    for(i=0; i<2; i++) int_xor_1[i] = IntXor(64);

    for(i=0; i<2; i++)
    {
        int_xor_1[i].a <== T[i];
        int_xor_1[i].b <== N_64[i];

        T[i] = int_xor_1[i].out;
    }

    new_TAG[0] = T[0];
    new_TAG[1] = T[1];

    var new_TAG_8[16];
    component typecast_10 = Typecast(2, 64, 8);
    for(i=0; i<2; i++) typecast_10.in[i] <== new_TAG[i];
    new_TAG_8 = typecast_10.out;

    component int_and_1 = IntAnd(8);
    int_and_1.a <== new_TAG_8[15];
    int_and_1.b <== 127;
    new_TAG_8[15] = int_and_1.out;

    var new_TAG_32[4];
    component typecast_11 = Typecast(16, 8, 32);
    for(i=0; i<16; i++) typecast_11.in[i] <== new_TAG_8[i];
    new_TAG_32 = typecast_11.out;

    component aes_256_encrypt_2 = AES256Encrypt();
    for(i=0; i<4; i++) aes_256_encrypt_2.in[i] <== new_TAG_32[i];
    for(i=0; i<60; i++) aes_256_encrypt_2.ks[i] <== ks[i];
    new_TAG_32 = aes_256_encrypt_2.out;

    var new_TAG_64[2];
    component typecast_12 = Typecast(4, 32, 64);
    for(i=0; i<4; i++) typecast_12.in[i] <== new_TAG_32[i];
    new_TAG_64 = typecast_12.out;

    component is_equal_1[2];
    for(i=0; i<2; i++) is_equal_1[i] = IsEqual();

    for(i=0; i<2; i++)
    {
        is_equal_1[i].in[0] <== new_TAG_64[i];
        is_equal_1[i].in[1] <== TAG_64_1[i];
    }

    component mux_1 = Mux1();
    mux_1.c[0] <== 0;
    mux_1.c[1] <== 1;
    mux_1.s <== is_equal_1[0].out * is_equal_1[1].out;

    success <== mux_1.out;

    component mux_2[msg_len];
    for(i=0; i<msg_len; i++) mux_2[i] = Mux1();

    for(i=0; i<msg_len; i++)
    {
        mux_2[i].c[0] <== CT[i];
        mux_2[i].c[1] <== MSG_t[i];
        mux_2[i].s <== is_equal_1[0].out * is_equal_1[1].out;

        MSG[i] <== mux_2[i].out;
    }
}