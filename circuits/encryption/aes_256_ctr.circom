pragma circom 2.0.0;

include "aes_256_encrypt.circom";
include "helper_functions.circom";

template AES256CTR(msg_len)
{
	signal input in[msg_len];
	signal input ctr[4];
	signal input ks[60];
	signal output out[msg_len];

	var EK[4];
	var p_index = 0, c_index = 0;
	var ctr_t[4] = ctr;
	var out_t[msg_len][8];

	var i, j, k, l;

	component num2bits_1[msg_len];
	for(i=0; i<msg_len; i++)
	{
		num2bits_1[i] = Num2Bits(8);
		num2bits_1[i].in <== in[i];
	}

	component aes_256_encrypt_1[msg_len/16];
	component num2bits_2[msg_len/16][4];
	component xor_1[msg_len/16][4][4][32];

	for(i=0; i<msg_len/16; i++)
	{
		aes_256_encrypt_1[i] = AES256Encrypt();
		for(j=0; j<4; j++) aes_256_encrypt_1[i].in[j] <== ctr_t[j];
		for(j=0; j<60; j++) aes_256_encrypt_1[i].ks[j] <== ks[j];

		EK = aes_256_encrypt_1[i].out;

		for(j=0; j<4; j++)
		{
			num2bits_2[i][j] = Num2Bits(32);
			num2bits_2[i][j].in <== EK[j];

			for(k=0; k<4; k++)
			{
				for(l=0; l<8; l++)
				{
					xor_1[i][j][k][l] = XOR();
					xor_1[i][j][k][l].a <== num2bits_1[i*16+j*4+k].out[l];
					xor_1[i][j][k][l].b <== num2bits_2[i][j].out[k*8+l];

					out_t[i*16+j*4+k][l] = xor_1[i][j][k][l].out;
				}
			}
		}
		ctr_t[0] += 1;
	}

	component bits2num_1[msg_len];
	for(i=0; i<msg_len; i++)
	{
		bits2num_1[i] = Bits2Num(8);
		for(j=0; j<8; j++) bits2num_1[i].in[j] <== out_t[i][j];
		out[i] <== bits2num_1[i].out;
	}
}
