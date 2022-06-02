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

    var emulated_aesenc_rijndael_sbox[256] = [99, 124, 119, 123, 242, 107, 111, 197, 48, 1, 103, 43, 254, 215, 171, 118, 202, 130, 201, 125, 250, 89, 71, 240, 173, 212, 162, 175, 156, 164, 114, 192, 183, 253, 147, 38, 54, 63, 247, 204, 52, 165, 229, 241, 113, 216, 49, 21, 4, 199, 35, 195, 24, 150, 5, 154, 7, 18, 128, 226, 235, 39, 178, 117, 9, 131, 44, 26, 27, 110, 90, 160, 82, 59, 214, 179, 41, 227, 47, 132, 83, 209, 0, 237, 32, 252, 177, 91, 106, 203, 190, 57, 74, 76, 88, 207, 208, 239, 170, 251, 67, 77, 51, 133, 69, 249, 2, 127, 80, 60, 159, 168, 81, 163, 64, 143, 146, 157, 56, 245, 188, 182, 218, 33, 16, 255, 243, 210, 205, 12, 19, 236, 95, 151, 68, 23, 196, 167, 126, 61, 100, 93, 25, 115, 96, 129, 79, 220, 34, 42, 144, 136, 70, 238, 184, 20, 222, 94, 11, 219, 224, 50, 58, 10, 73, 6, 36, 92, 194, 211, 172, 98, 145, 149, 228, 121, 231, 200, 55, 109, 141, 213, 78, 169, 108, 86, 244, 234, 101, 122, 174, 8, 186, 120, 37, 46, 28, 166, 180, 198, 232, 221, 116, 31, 75, 189, 139, 138, 112, 62, 181, 102, 72, 3, 246, 14, 97, 53, 87, 185, 134, 193, 29, 158, 225, 248, 152, 17, 105, 217, 142, 148, 155, 30, 135, 233, 206, 85, 40, 223, 140, 161, 137, 13, 191, 230, 66, 104, 65, 153, 45, 15, 176, 84, 187, 22];

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