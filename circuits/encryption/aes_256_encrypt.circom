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
	var s[4], t[4];
	
	var i,j,k,l;
	
	component multibit_xor_1[4];
	for(i=0; i<4; i++) multibit_xor_1[i] = MultibitXor(32);

	for(i=0; i<4; i++)
	{
		multibit_xor_1[i].a <== in[i];
		multibit_xor_1[i].b <== ks[i+ks_index];

		s[i] = multibit_xor_1[i].out;
	}
	ks_index += 4;
	
	component multibit_and_2[13][4][4];
	component multibit_xor_2[13][4][3];
	
	component multibit_xor_3[13][4];
	for(i=0; i<13; i++)
	{
		for(j=0; j<4; j++)
		{
			for(k=0; k<4; k++) multibit_and_2[i][j][k] = MultibitAnd(32);
			for(k=0; k<3; k++) multibit_xor_2[i][j][k] = MultibitXor(32);
			multibit_xor_3[i][j] = MultibitXor(32);
		}
	}
	
	for(i=0; i<13; i++)
	{
		
		for(j=0; j<4; j++)
		{
			for(k=0; k<4; k++)
			{
				var tmp;

				tmp = right_shift(s[(j+k)%4], k*8);

				multibit_and_2[i][j][k].a <== tmp;
				multibit_and_2[i][j][k].b <== 0xff;

				tmp = emulated_aesenc_enc_table(k,multibit_and_2[i][j][k].out);	


				if(k==0) multibit_xor_2[i][j][0].a <-- tmp;
				else if(k<3)
				{	
					multibit_xor_2[i][j][k-1].b <-- tmp;
					multibit_xor_2[i][j][k].a <== multibit_xor_2[i][j][k-1].out;
					
				}
				else
				{
					multibit_xor_2[i][j][2].b <-- tmp;
					multibit_xor_3[i][j].a <== multibit_xor_2[i][j][2].out;
				}
			}
		}


		for(j=0; j<4; j++)
		{
			multibit_xor_3[i][j].b <== ks[j+ks_index];	
			s[j] = multibit_xor_3[i][j].out;
		}
		
		ks_index += 4;
	}

	component row_shifting = EmulatedAesencRowShifting();
	
	for(i=0; i<4; i++) row_shifting.in[i] <== s[i];
	for(i=0; i<4; i++) s[i] = row_shifting.out[i];

	component sub_bytes = EmulatedAesencSubstituteBytes();
	
	for(i=0; i<4; i++) sub_bytes.in[i] <== s[i];
	for(i=0; i<4; i++) s[i] = sub_bytes.out[i];

	component multibit_xor[4];
	for(i=0; i<4; i++) multibit_xor[i] = MultibitXor(32);

	for(i=0; i<4; i++)
	{
		multibit_xor[i].a <== s[i];
		multibit_xor[i].b <== ks[i+ks_index];

		out[i] <== multibit_xor[i].out;
	}
	
}

component main = AES256Encrypt();
