function buffer2bits(buff) {
	const res = [];
	for (let i = 0; i < buff.length; i++) {
		for (let j = 0; j < 8; j++) {
			if ((buff[i] >> 7-j) & 1) {
				res.push(1n);
			} else {
				res.push(0n);
			}
		}
	}
	return res;
}

function convertToLength(hexInput, len) {
	while (hexInput.length  != len) {
		hexInput = '0' + hexInput;
	}
	return hexInput;
}

function intToLEBuffer(x, bufSize) {
	return Buffer.from(convertToLength(x.toString(16), bufSize*2), 'hex').reverse()
}

module.exports = {
    buffer2bits,
    convertToLength,
    intToLEBuffer
};