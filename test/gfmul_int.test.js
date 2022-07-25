const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;
const Module = require("./module.js");
const utils = require("./utils");

describe("GFmul test", () => {
    it("Show do gf multiplication correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","gfmul_int_test.circom"));
        const a = [BigInt("1"),BigInt("0")];
        const b = [BigInt("4876465869548802997"),BigInt("9173032812820655379")];
        // const res = [BigInt("1447496719058453797"),BigInt("10021191554797066756")];
        var res = [];
        const res_len = 2;

        const a_ptr = Module._malloc(a.length * BigUint64Array.BYTES_PER_ELEMENT);
        const b_ptr = Module._malloc(b.length * BigUint64Array.BYTES_PER_ELEMENT);
        const res_ptr = Module._malloc(res_len * BigUint64Array.BYTES_PER_ELEMENT);

        Module.HEAPU64.set(new BigUint64Array(a), a_ptr/BigUint64Array.BYTES_PER_ELEMENT);
        Module.HEAPU64.set(new BigUint64Array(b), b_ptr/BigUint64Array.BYTES_PER_ELEMENT);

        Module._gfmul_int(a_ptr, b_ptr, res_ptr);

        for(let i=0; i<res_len; i++)
        {
            res.push(BigInt(Module.HEAPU64[res_ptr/BigUint64Array.BYTES_PER_ELEMENT + i]));
        }

        var a0_buffer = [...utils.intToLEBuffer(a[0], 8)];
        var a0_bits = utils.buffer2bits(a0_buffer);

        var a1_buffer = [...utils.intToLEBuffer(a[1], 8)];
        var a1_bits = utils.buffer2bits(a1_buffer);

        var b0_buffer = [...utils.intToLEBuffer(b[0], 8)];
        var b0_bits = utils.buffer2bits(b0_buffer);

        var b1_buffer = [...utils.intToLEBuffer(b[1], 8)];
        var b1_bits = utils.buffer2bits(b1_buffer);

        var res_buffer = [];
        for(let i=0; i<res.length; i++)
        {
            res_buffer.push(...utils.intToLEBuffer(res[i], 8));
        }
        var res_bits = utils.buffer2bits(res_buffer);

        let witness = await cir.calculateWitness({"a": [a0_bits,a1_bits], "b": [b0_bits, b1_bits]});
        witness = witness.slice(1, 129);
        assert.ok(res_bits.every((v, i)=> v == witness[i]));
    });
});
