pragma circom 2.0.0;

include "../circomlib/circuits/bitify.circom";
include "../circomlib/circuits/gates.circom";

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
