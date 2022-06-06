pragma circom 2.0.0;

include "leftshift.circom";
include "xor2.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "indexselector.circom";
include "bitwiseand.circom";
include "rightshift.circom";

template AES256KeyExpansion() {
    signal input key[32]; 
    // signal input w[60];
    signal output w[60];

    // Taken from: https://github.com/Shay-Gueron/AES-GCM-SIV/blob/master/AES_GCM_SIV_256/AES_GCM_SIV_256_Reference_Code/aes_emulation_tables.c#L351
    var emulated_aesenc_rijndael_sbox[256] = [
        0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5,
        0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
        0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
        0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
        0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc,
        0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
        0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a,
        0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
        0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
        0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
        0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b,
        0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
        0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85,
        0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
        0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
        0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
        0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17,
        0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
        0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88,
        0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
        0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
        0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
        0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9,
        0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
        0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6,
        0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
        0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
        0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
        0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94,
        0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
        0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68,
        0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
    ];

    var rcon[10] = [1, 2, 4, 8, 16, 32, 64, 128, 27, 54];

    var Nk = 8;
    var Nb = 4;
    var Nr = 14;
    var temp;
    var i;

    // for(i=0; i<Nk; i++) {
    //     //w[i] = key[4*i] ^ (key[4*i+1]<<8) ^ (key[4*i+2]<<16) ^ (key[4*i+3]<<24);
    // }

    component a_tobits[Nk];
    component b_tobits[Nk];
    component c_tobits[Nk];
    component d_tobits[Nk];
    component a_shiftleft[Nk];
    component b_shiftleft[Nk];
    component c_shiftleft[Nk];
    component d_shiftleft[Nk];
    component ab_xor_1[Nk];
    component cd_xor[Nk];
    component abcd_xor_1[Nk];
    component iter_num[Nk];

    for(i = 0; i<Nk; i++) {
        a_tobits[i] = Num2Bits(32);
        b_tobits[i] = Num2Bits(32);
        c_tobits[i] = Num2Bits(32);
        d_tobits[i] = Num2Bits(32);
        a_shiftleft[i] = LeftShiftBitwise(32, 0);
        b_shiftleft[i] = LeftShiftBitwise(32, 8);
        c_shiftleft[i] = LeftShiftBitwise(32, 16);
        d_shiftleft[i] = LeftShiftBitwise(32, 24);
        ab_xor_1[i] = Xor2(32);
        cd_xor[i] = Xor2(32);
        abcd_xor_1[i] = Xor2(32);
        iter_num[i] = Bits2Num(32);
        a_tobits[i].in <== key[4*i];
        b_tobits[i].in <== key[4*i+1];
        c_tobits[i].in <== key[4*i+2];
        d_tobits[i].in <== key[4*i+3];
        for(var iter=0; iter<32; iter++){
            a_shiftleft[i].in[iter] <== a_tobits[i].out[iter];
            b_shiftleft[i].in[iter] <== b_tobits[i].out[iter];
            c_shiftleft[i].in[iter] <== c_tobits[i].out[iter];
            d_shiftleft[i].in[iter] <== d_tobits[i].out[iter];
        }
        for(var iter=0; iter<32; iter++){
            ab_xor_1[i].a[iter] <== a_shiftleft[i].out[iter];
            ab_xor_1[i].b[iter] <== b_shiftleft[i].out[iter];
        }
        for(var iter=0; iter<32; iter++){
            cd_xor[i].a[iter] <== c_shiftleft[i].out[iter];
            cd_xor[i].b[iter] <== d_shiftleft[i].out[iter];
        }
        for(var iter=0; iter<32; iter++){
            abcd_xor_1[i].a[iter] <== ab_xor_1[i].out[iter];
            abcd_xor_1[i].b[iter] <== cd_xor[i].out[iter];
        }
        for(var iter=0; iter<32; iter++){
            iter_num[i].in[iter] <== abcd_xor_1[i].out[iter];
        }
        w[i] <== iter_num[i].out;
    }

    
    // var temp;
    component oxffBin = Num2Bits(32);
    oxffBin.in <== 255;
    component prevWbits[Nb*(Nr+1)]; //= Num2Bits(32);
    component a_and[Nb*(Nr+1)];
    component a_rijndaelVal[Nb*(Nr+1)];
    component a_bits2Num_1[Nb*(Nr+1)];
    component a_leftshift[Nb*(Nr+1)];
    component a_Num2bits_1[Nb*(Nr+1)];

    component b_rightshift[Nb*(Nr+1)];
    component b_and[Nb*(Nr+1)];
    component b_bits2Num[Nb*(Nr+1)];
    component b_rijndaelVal[Nb*(Nr+1)];
    component b_Num2bits[Nb*(Nr+1)];
    component b_leftshift[Nb*(Nr+1)];

    component c_rightshift[Nb*(Nr+1)];
    component c_and[Nb*(Nr+1)];
    component c_bits2Num[Nb*(Nr+1)];
    component c_rijndaelVal[Nb*(Nr+1)];
    component c_Num2bits[Nb*(Nr+1)];
    component c_leftshift[Nb*(Nr+1)];

    component d_rightshift[Nb*(Nr+1)];
    component d_and[Nb*(Nr+1)];
    component d_bits2Num[Nb*(Nr+1)];
    component d_rijndaelVal[Nb*(Nr+1)];
    component d_Num2bits[Nb*(Nr+1)];
    component d_leftshift[Nb*(Nr+1)];

    component e_rbox[Nb*(Nr+1)];
    component e_Num2bits[Nb*(Nr+1)];

    component ab_xor[Nb*(Nr+1)];
    component abc_xor[Nb*(Nr+1)];
    component abcd_xor[Nb*(Nr+1)];
    component abcde_xor[Nb*(Nr+1)];

    component f_rightshift[Nb*(Nr+1)];
    component f_and[Nb*(Nr+1)];
    component f_bits2Num[Nb*(Nr+1)];
    component f_rijndaelVal[Nb*(Nr+1)];
    component f_Num2bits[Nb*(Nr+1)];
    component f_leftshift[Nb*(Nr+1)];

    component g_rightshift[Nb*(Nr+1)];
    component g_and[Nb*(Nr+1)];
    component g_bits2Num[Nb*(Nr+1)];
    component g_rijndaelVal[Nb*(Nr+1)];
    component g_Num2bits[Nb*(Nr+1)];
    component g_leftshift[Nb*(Nr+1)];

    component h_rightshift[Nb*(Nr+1)];
    component h_and[Nb*(Nr+1)];
    component h_bits2Num[Nb*(Nr+1)];
    component h_rijndaelVal[Nb*(Nr+1)];
    component h_Num2bits[Nb*(Nr+1)];
    component h_leftshift[Nb*(Nr+1)];

    component i_rightshift[Nb*(Nr+1)];
    component i_bits2Num[Nb*(Nr+1)];
    component i_rijndaelVal[Nb*(Nr+1)];
    component i_Num2bits[Nb*(Nr+1)];
    component i_leftshift[Nb*(Nr+1)];

    component fg_xor[Nb*(Nr+1)];
    component fgh_xor[Nb*(Nr+1)];
    component fghi_xor[Nb*(Nr+1)];

    component prevNkWbits[Nb*(Nr+1)];

    component final_xor[Nb*(Nr+1)];

    component final2Num[Nb*(Nr+1)];

    for(i=8; i<(Nb*(Nr+1)); i++) {
        prevWbits[i] = Num2Bits(32);
        prevWbits[i].in <== w[i-1];
        prevNkWbits[i] = Num2Bits(32);
        prevNkWbits[i].in <== w[i-Nk];

        // temp = w[i-1];
        if(i%Nk == 0){
            //statement a
            a_and[i] = BitwiseAnd(32);
            for(var iter=0; iter<32; iter++){
                a_and[i].a[iter] <== prevWbits[i].out[iter];
                a_and[i].b[iter] <== oxffBin.out[iter];
            }
            a_bits2Num_1[i] = Bits2Num(32);
            for(var iter=0; iter<32; iter++){
                a_bits2Num_1[i].in[iter] <== a_and[i].out[iter]; 
            }
            a_rijndaelVal[i] = IndexSelector(256);
            for(var iter=0; iter<256; iter++){
                a_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
            }
            a_rijndaelVal[i].index <== a_bits2Num_1[i].out;
            a_Num2bits_1[i] = Num2Bits(32);
            a_Num2bits_1[i].in <== a_rijndaelVal[i].out;
            a_leftshift[i] = LeftShiftBitwise(32, 24);
            for(var iter = 0; iter<32; iter++){
                a_leftshift[i].in[iter] <== a_Num2bits_1[i].out[iter]; // statement a result
            }
            //--
            b_rightshift[i] = RightShiftBitwise(32, 8);
            for(var iter=0; iter<32; iter++){
                b_rightshift[i].in[iter] <== prevWbits[i].out[iter];
            }
            b_and[i] = BitwiseAnd(32);
            for(var iter=0; iter<32; iter++){
                b_and[i].a[iter] <== b_rightshift[i].out[iter];
                b_and[i].b[iter] <== oxffBin.out[iter];
            }
            b_bits2Num[i] = Bits2Num(32);
            for(var iter=0; iter<32; iter++){
                b_bits2Num[i].in[iter] <== b_and[i].out[iter];
            }

            b_rijndaelVal[i] = IndexSelector(256);
            for(var iter = 0; iter<256; iter++){
                b_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
            }
            b_rijndaelVal[i].index <== b_bits2Num[i].out;
            b_Num2bits[i] = Num2Bits(32);
            b_Num2bits[i].in <== b_rijndaelVal[i].out;

            b_leftshift[i] = LeftShiftBitwise(32, 0);
            for(var iter=0; iter<32; iter++){
                b_leftshift[i].in[iter] <== b_Num2bits[i].out[iter]; // statement b result
            }

            //---

            c_rightshift[i] = RightShiftBitwise(32, 16);
            for(var iter=0; iter<32; iter++){
                c_rightshift[i].in[iter] <== prevWbits[i].out[iter];
            }
            c_and[i] = BitwiseAnd(32);
            for(var iter=0; iter<32; iter++){
                c_and[i].a[iter] <== c_rightshift[i].out[iter];
                c_and[i].b[iter] <== oxffBin.out[iter];
            }
            c_bits2Num[i] = Bits2Num(32);
            for(var iter=0; iter<32; iter++){
                c_bits2Num[i].in[iter] <== c_and[i].out[iter];
            }

            c_rijndaelVal[i] = IndexSelector(256);
            for(var iter = 0; iter<256; iter++){
                c_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
            }
            c_rijndaelVal[i].index <== c_bits2Num[i].out;
            c_Num2bits[i] = Num2Bits(32);
            c_Num2bits[i].in <== c_rijndaelVal[i].out;

            c_leftshift[i] = LeftShiftBitwise(32, 8);
            for(var iter=0; iter<32; iter++){
                c_leftshift[i].in[iter] <== c_Num2bits[i].out[iter]; // statement c result
            }


            //d --
            d_rightshift[i] = RightShiftBitwise(32, 24);
            for(var iter=0; iter<32; iter++){
                d_rightshift[i].in[iter] <== prevWbits[i].out[iter];
            }
            d_bits2Num[i] = Bits2Num(32);
            for(var iter=0; iter<32; iter++){
                d_bits2Num[i].in[iter] <== d_rightshift[i].out[iter];
            }

            d_rijndaelVal[i] = IndexSelector(256);
            for(var iter = 0; iter<256; iter++){
                d_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
            }
            d_rijndaelVal[i].index <== d_bits2Num[i].out;
            d_Num2bits[i] = Num2Bits(32);
            d_Num2bits[i].in <== d_rijndaelVal[i].out;

            d_leftshift[i] = LeftShiftBitwise(32, 16);
            for(var iter=0; iter<32; iter++){
                d_leftshift[i].in[iter] <== d_Num2bits[i].out[iter]; // statement d result
            }

            //e --
            e_rbox[i] = IndexSelector(10);
            for(var iter = 0; iter<10; iter++){
                e_rbox[i].in[iter] <== rcon[iter];
            }
            e_rbox[i].index <== (i/Nk-1);
            e_Num2bits[i] = Num2Bits(32);
            e_Num2bits[i].in <== e_rbox[i].out; // statement e result

            ab_xor[i] = Xor2(32);
            for(var iter = 0; iter<32; iter++){
                ab_xor[i].a[iter] <== a_leftshift[i].out[iter];
                ab_xor[i].b[iter] <== b_leftshift[i].out[iter];
            }
            abc_xor[i] = Xor2(32);
            for(var iter = 0; iter<32; iter++){
                abc_xor[i].a[iter] <== ab_xor[i].out[iter];
                abc_xor[i].b[iter] <== c_leftshift[i].out[iter];
            }
            abcd_xor[i] = Xor2(32);
            for(var iter = 0; iter<32; iter++){
                abcd_xor[i].a[iter] <== abc_xor[i].out[iter];
                abcd_xor[i].b[iter] <== d_leftshift[i].out[iter];
            }
            abcde_xor[i] = Xor2(32);
            for(var iter = 0; iter<32; iter++){
                abcde_xor[i].a[iter] <== abcd_xor[i].out[iter];
                abcde_xor[i].b[iter] <== e_Num2bits[i].out[iter]; // final xor result
            }

            final_xor[i] = Xor2(32);
            for(var iter=0; iter<32; iter++){
                final_xor[i].a[iter] <== abcde_xor[i].out[iter];
                final_xor[i].b[iter] <== prevNkWbits[i].out[iter];
            }

            final2Num[i] = Bits2Num(32);
            for(var iter=0; iter<32; iter++){
                final2Num[i].in[iter] <== final_xor[i].out[iter];
            }
            w[i] <== final2Num[i].out;
            // temp = 
            //  (emulated_aesenc_rijndael_sbox[(temp      ) & 255] << 24) ^  // statement a
			//  (emulated_aesenc_rijndael_sbox[(temp >>  8) & 255] << 0) ^      // statement b
			// 	(emulated_aesenc_rijndael_sbox[(temp >> 16) & 255] << 8) ^      // statement c
			// 	(emulated_aesenc_rijndael_sbox[(temp >> 24)       ] << 16) ^    // statement d
			// 	rcon[i/Nk-1];                                                   // statement e
        }
        else{
            if((i%Nk)==4){
                // f--
                f_rightshift[i] = RightShiftBitwise(32, 0);
                for(var iter=0; iter<32; iter++){
                    f_rightshift[i].in[iter] <== prevWbits[i].out[iter];
                }
                f_and[i] = BitwiseAnd(32);
                for(var iter=0; iter<32; iter++){
                    f_and[i].a[iter] <== f_rightshift[i].out[iter];
                    f_and[i].b[iter] <== oxffBin.out[iter];
                }
                f_bits2Num[i] = Bits2Num(32);
                for(var iter=0; iter<32; iter++){
                    f_bits2Num[i].in[iter] <== f_and[i].out[iter];
                }

                f_rijndaelVal[i] = IndexSelector(256);
                for(var iter = 0; iter<256; iter++){
                    f_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
                }
                f_rijndaelVal[i].index <== f_bits2Num[i].out;
                f_Num2bits[i] = Num2Bits(32);
                f_Num2bits[i].in <== f_rijndaelVal[i].out;

                f_leftshift[i] = LeftShiftBitwise(32, 0);
                for(var iter=0; iter<32; iter++){
                    f_leftshift[i].in[iter] <== f_Num2bits[i].out[iter]; // statement f result
                }

                //g--
                g_rightshift[i] = RightShiftBitwise(32, 8);
                for(var iter=0; iter<32; iter++){
                    g_rightshift[i].in[iter] <== prevWbits[i].out[iter];
                }
                g_and[i] = BitwiseAnd(32);
                for(var iter=0; iter<32; iter++){
                    g_and[i].a[iter] <== g_rightshift[i].out[iter];
                    g_and[i].b[iter] <== oxffBin.out[iter];
                }
                g_bits2Num[i] = Bits2Num(32);
                for(var iter=0; iter<32; iter++){
                    g_bits2Num[i].in[iter] <== g_and[i].out[iter];
                }

                g_rijndaelVal[i] = IndexSelector(256);
                for(var iter = 0; iter<256; iter++){
                    g_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
                }
                g_rijndaelVal[i].index <== g_bits2Num[i].out;
                g_Num2bits[i] = Num2Bits(32);
                g_Num2bits[i].in <== g_rijndaelVal[i].out;

                g_leftshift[i] = LeftShiftBitwise(32, 8);
                for(var iter=0; iter<32; iter++){
                    g_leftshift[i].in[iter] <== g_Num2bits[i].out[iter]; // statement g result
                }

                //h--
                h_rightshift[i] = RightShiftBitwise(32, 16);
                for(var iter=0; iter<32; iter++){
                    h_rightshift[i].in[iter] <== prevWbits[i].out[iter];
                }
                h_and[i] = BitwiseAnd(32);
                for(var iter=0; iter<32; iter++){
                    h_and[i].a[iter] <== h_rightshift[i].out[iter];
                    h_and[i].b[iter] <== oxffBin.out[iter];
                }
                h_bits2Num[i] = Bits2Num(32);
                for(var iter=0; iter<32; iter++){
                    h_bits2Num[i].in[iter] <== h_and[i].out[iter];
                }

                h_rijndaelVal[i] = IndexSelector(256);
                for(var iter = 0; iter<256; iter++){
                    h_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
                }
                h_rijndaelVal[i].index <== h_bits2Num[i].out;
                h_Num2bits[i] = Num2Bits(32);
                h_Num2bits[i].in <== h_rijndaelVal[i].out;

                h_leftshift[i] = LeftShiftBitwise(32, 16);
                for(var iter=0; iter<32; iter++){
                    h_leftshift[i].in[iter] <== h_Num2bits[i].out[iter]; // statement h result
                }

                // i--
                i_rightshift[i] = RightShiftBitwise(32, 24);
                for(var iter=0; iter<32; iter++){
                    i_rightshift[i].in[iter] <== prevWbits[i].out[iter];
                }

                i_bits2Num[i] = Bits2Num(32);
                for(var iter=0; iter<32; iter++){
                    i_bits2Num[i].in[iter] <== i_rightshift[i].out[iter];
                }

                i_rijndaelVal[i] = IndexSelector(256);
                for(var iter = 0; iter<256; iter++){
                    i_rijndaelVal[i].in[iter] <== emulated_aesenc_rijndael_sbox[iter];
                }
                i_rijndaelVal[i].index <== i_bits2Num[i].out;
                i_Num2bits[i] = Num2Bits(32);
                i_Num2bits[i].in <== i_rijndaelVal[i].out;

                i_leftshift[i] = LeftShiftBitwise(32, 24);
                for(var iter=0; iter<32; iter++){
                    i_leftshift[i].in[iter] <== i_Num2bits[i].out[iter]; // statement i result
                }

                fg_xor[i] = Xor2(32);
                for(var iter=0 ;iter<32; iter++){
                    fg_xor[i].a[iter] <== f_leftshift[i].out[iter];
                    fg_xor[i].b[iter] <== g_leftshift[i].out[iter];
                }
                fgh_xor[i] = Xor2(32);
                for(var iter=0; iter<32; iter++){
                    fgh_xor[i].a[iter] <== fg_xor[i].out[iter];
                    fgh_xor[i].b[iter] <== h_leftshift[i].out[iter];
                }
                fghi_xor[i] = Xor2(32);
                for(var iter=0; iter<32; iter++){
                    fghi_xor[i].a[iter] <== fgh_xor[i].out[iter];
                    fghi_xor[i].b[iter] <== i_leftshift[i].out[iter];
                }

                final_xor[i] = Xor2(32);
                for(var iter=0; iter<32; iter++){
                    final_xor[i].a[iter] <== fghi_xor[i].out[iter];
                    final_xor[i].b[iter] <== prevNkWbits[i].out[iter];
                }

                final2Num[i] = Bits2Num(32);
                for(var iter=0; iter<32; iter++){
                    final2Num[i].in[iter] <== final_xor[i].out[iter];
                }
                w[i] <== final2Num[i].out;
            // 	temp = (emulated_aesenc_rijndael_sbox[(temp      ) & 255] << 0) ^   // statement f
            // 	       (emulated_aesenc_rijndael_sbox[(temp >>  8) & 255] << 8) ^   // statement g
            // 		   (emulated_aesenc_rijndael_sbox[(temp >> 16) & 255] << 16) ^  // statement h
            // 		   (emulated_aesenc_rijndael_sbox[(temp >> 24) ] << 24);         // statement i
            }
            else{
                final_xor[i] = Xor2(32);
                for(var iter=0; iter<32; iter++){
                    final_xor[i].a[iter] <== prevWbits[i].out[iter];
                    final_xor[i].b[iter] <== prevNkWbits[i].out[iter];
                }

                final2Num[i] = Bits2Num(32);
                for(var iter=0; iter<32; iter++){
                    final2Num[i].in[iter] <== final_xor[i].out[iter];
                }
                w[i] <== final2Num[i].out;
                // w[i] <== w[i-Nk]^w[i-1]
            }
        }
    }
}
