pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "aes_emulation_tables.circom";

template EmulatedAesencRowShifting()
{
	signal input in[4];
	signal output out[4];
	
	var byte_order[16];
	byte_order[0]  = 0;
	byte_order[1]  = 5;
	byte_order[2]  = 10;
	byte_order[3]  = 15;
	byte_order[4]  = 4;
	byte_order[5]  = 9;
	byte_order[6]  = 14;
	byte_order[7]  = 3;
	byte_order[8]  = 8;
	byte_order[9]  = 13;
	byte_order[10] = 2;
	byte_order[11] = 7;
	byte_order[12] = 12;
	byte_order[13] = 1;
	byte_order[14] = 6;
	byte_order[15] = 11;

	var src[16][8], dst[16][8];
	
	var i, j, k;

	component num2bits_1[4];
	for(i=0; i<4; i++) num2bits_1[i] = Num2Bits(32);
	
	for(i=0; i<4; i++)
	{
		num2bits_1[i].in <== in[i];
		for(j=0; j<4; j++)
		{
			for(k=0; k<8; k++) src[i*4+j][k] = num2bits_1[i].out[j*8+k];
		}
	}

	for(i=0; i<16; i++) dst[i] = src[byte_order[i]];

	component bits2num_1[4];
	for(i=0; i<4; i++) bits2num_1[i] = Bits2Num(32);

	for(i=0; i<4; i++)
	{
		for(j=0; j<4; j++)
		{
			for(k=0; k<8; k++) bits2num_1[i].in[j*8+k] <== dst[i*4+j][k];
		}

		out[i] <== bits2num_1[i].out;
	}
}

template EmulatedAesencSubstituteBytes()
{
	signal input in[4];
	signal output out[4];

	
	var ptr[16];
	
	var i, j, k;

	component num2bits_1[4];
	for(i=0; i<4; i++) num2bits_1[i] = Num2Bits(32);
	
	component bits2num_1[16];
	for(i=0; i<16; i++) bits2num_1[i] = Bits2Num(8);

	for(i=0; i<4; i++)
	{
		num2bits_1[i].in <== in[i];
		for(j=0; j<4; j++)
		{
			for(k=0; k<8; k++) bits2num_1[i*4+j].in[k] <== num2bits_1[i].out[j*8+k];
			ptr[i*4+j] = bits2num_1[i*4+j].out;
		}
	}

	for(i=0; i<16; i++)
	{
		ptr[i] = emulated_aesenc_rijndael_sbox(ptr[i]);
	}

	component num2bits_2[16];
	for(i=0; i<16; i++) num2bits_2[i] = Num2Bits(8);
	
	component bits2num_2[4];
	for(i=0; i<4; i++) bits2num_2[i] = Bits2Num(32);

	for(i=0; i<4; i++)
	{
		for(j=0; j<4; j++)
		{
			num2bits_2[i*4+j].in <-- ptr[i*4+j];
			for(k=0; k<8; k++) bits2num_2[i].in[j*8+k] <== num2bits_2[i*4+j].out[k];
		}

		out[i] <== bits2num_2[i].out;
	}
	
}
