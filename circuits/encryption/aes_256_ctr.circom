pragma circom 2.0.0;

include "aes_256_encrypt.circom";
include "helper_functions.circom";

template AES256CTR(msg_len)
{
	signal input in[msg_len];
	signal input ctr[4];
	signal input ks[60];
	signal output out[msg_len];

	var EK[4], P[msg_len/4], C[msg_len/4];
	var p_index = 0, c_index = 0;
	var ctr_t[4] = ctr;

	var i, j, k, l;

	component num2bits_1[msg_len];
	component bits2num_1[msg_len/4];
	for(i=0; i<msg_len; i++) num2bits_1[i] = Num2Bits(8);
	for(i=0; i<msg_len/4; i++) bits2num_1[i] = Bits2Num(32);

	for(i=0; i<msg_len/4; i++)
	{
		for(j=0; j<4; j++)
		{
			var index = i*4+j;
			num2bits_1[index].in <== in[index];
			for(k=0; k<8; k++) bits2num_1[i].in[j*8+k] <== num2bits_1[index].out[k];
		}
		P[i] = bits2num_1[i].out;
	}

	component aes_256_encrypt_2[msg_len/16];
	component multibit_xor_2[msg_len/16][4];
	component multibit_and_2[msg_len/16];
	for(i=0; i<msg_len/16; i++)
	{
		aes_256_encrypt_2[i] = AES256Encrypt();
		multibit_and_2[i] = MultibitAnd(32);
		for(j=0; j<4; j++) multibit_xor_2[i][j] = MultibitXor(32);
	}

	for(i=0; i<msg_len/16; i++)
	{
		for(j=0; j<4; j++) aes_256_encrypt_2[i].in[j] <== ctr_t[j];
		for(j=0; j<60; j++) aes_256_encrypt_2[i].ks[j] <== ks[j];

		EK = aes_256_encrypt_2[i].out;
		
		for(j=0; j<4; j++)
		{
			multibit_xor_2[i][j].a <== EK[j];
			multibit_xor_2[i][j].b <== P[p_index+j];

			C[c_index+j] = multibit_xor_2[i][j].out;
		}
		p_index += 4;
		c_index += 4;

		multibit_and_2[i].a <== ctr_t[0]+1;
		multibit_and_2[i].b <== 0xFFFFFFFF;

		ctr_t[0] = multibit_and_2[i].out;

	}

	component num2bits_3[msg_len/4];
	component bits2num_3[msg_len];
	for(i=0; i<msg_len/4; i++) num2bits_3[i] = Num2Bits(32);
	for(i=0; i<msg_len; i++) bits2num_3[i] = Bits2Num(8);

	for(i=0; i<msg_len/4; i++)
	{
		num2bits_3[i].in <== C[i];
		for(j=0; j<4; j++)
		{	
			var index = i*4+j;
			for(k=0; k<8; k++) bits2num_3[index].in[k] <== num2bits_3[i].out[j*8+k];
			out[index] <== bits2num_3[index].out;
		}
	}
}
