pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/gates.circom";

template RightShift(n, x)
{	
	signal input in;
	signal output out;
	
	component num2bits = Num2Bits(n);
	num2bits.in <== in;

	component bits2num = Bits2Num(n);
	var i;
	for(i=0; i<n; i++)
	{
		if(i+x<n) bits2num.in[i] <== num2bits.out[i+x];
		else bits2num.in[i] <== 0;
	} 
	out <== bits2num.out;
}

template LeftShift(n, x)
{	
	signal input in;
	signal output out;
	
	component num2bits = Num2Bits(n);
	num2bits.in <== in;

	component bits2num = Bits2Num(n);
	for(var i=0; i<n; i++)
	{
		if(i<x) bits2num.in[i] <== 0;
		else bits2num.in[i] <== num2bits.out[i-x];
	}
	out <== bits2num.out;
}

template MultibitXor(n)
{
	signal input a;
	signal input b;

	signal output out;

	component num2bits[2];
	num2bits[0] = Num2Bits(n);
	num2bits[1] = Num2Bits(n);

	num2bits[0].in <== a;
	num2bits[1].in <== b;
	
	component xor[n];
	for(var i=0; i<n; i++) xor[i] = XOR();

	component bits2num = Bits2Num(n);
	for(var i=0; i<n; i++)
	{
		xor[i].a <== num2bits[0].out[i];
		xor[i].b <== num2bits[1].out[i];

		bits2num.in[i] <== xor[i].out;
	}

	out <== bits2num.out;
}

template MultibitAnd(n)
{
	signal input a;
	signal input b;

	signal output out;

	component num2bits[2];
	num2bits[0] = Num2Bits(n);
	num2bits[1] = Num2Bits(n);

	num2bits[0].in <== a;
	num2bits[1].in <== b;
	component and[n];
	for(var i=0; i<n; i++) and[i] = AND();

	component bits2num = Bits2Num(n);
	for(var i=0; i<n; i++)
	{
		and[i].a <== num2bits[0].out[i];
		and[i].b <== num2bits[1].out[i];
		bits2num.in[i] <== and[i].out;
	}

	out <== bits2num.out;
}

template MultibitOr(n)
{
	signal input a;
	signal input b;

	signal output out;

	component num2bits[2];
	num2bits[0] = Num2Bits(n);
	num2bits[1] = Num2Bits(n);

	num2bits[0].in <== a;
	num2bits[1].in <== b;
	component or[n];
	for(var i=0; i<n; i++) or[i] = OR();

	component bits2num = Bits2Num(n);
	for(var i=0; i<n; i++)
	{
		or[i].a <== num2bits[0].out[i];
		or[i].b <== num2bits[1].out[i];
		bits2num.in[i] <== or[i].out;
	}

	out <== bits2num.out;
}

template Typecast(in_size, in_bits, out_bits)
{

	var out_size = (in_size*in_bits)/out_bits;
	signal input in[in_size];
	signal output out[out_size];

	var i, j, k;

	component num2bits[in_size];
	for(i=0; i<in_size; i++) num2bits[i] = Num2Bits(in_bits);

	component bits2num[out_size];
	for(i=0; i<out_size; i++) bits2num[i] = Bits2Num(out_bits);

	if(in_bits > out_bits)
	{
		var ratio = in_bits/out_bits;
		for(i=0; i<in_size; i++)
		{
			num2bits[i].in <== in[i];
			for(j=0; j<ratio; j++){
				var index = i*ratio + j;
				for(k=0; k<out_bits; k++) bits2num[index].in[k] <== num2bits[i].out[j*out_bits+k];
				out[index] <== bits2num[index].out;
			}
		}
	}
	else if(out_bits > in_bits)
	{
		var ratio = out_bits/in_bits;
		for(i=0; i<out_size; i++)
		{
			for(j=0; j<ratio; j++)
			{
				var index = i*ratio + j;
				num2bits[index].in <== in[index];
				for(k=0; k<in_bits; k++) bits2num[i].in[j*in_bits+k] <== num2bits[index].out[k];
			}
			out[i] <== bits2num[i].out;
		}
	}
}
