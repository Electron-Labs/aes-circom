const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;
const Module = require("./module.js");
const utils = require("./utils");

describe("Mul test", () => {
    it("Show do mul correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","mul_test.circom"));
        const a = BigInt("13979173243358019584");
        const b = BigInt("13333588315241340027");
        var res = [];
        const res_len = 2;

        const dst = Module._malloc(res_len * BigUint64Array.BYTES_PER_ELEMENT);
        Module._mul(a, b, dst);
        for(let i=0; i<res_len; i++)
        {
            res.push(BigInt(Module.HEAPU64[dst/BigInt64Array.BYTES_PER_ELEMENT+i]));
        }

        var a_buffer = [...utils.intToLEBuffer(a, 8)];
        var a_bits = utils.buffer2bits(a_buffer);

        var b_buffer = [...utils.intToLEBuffer(b, 8)];
        var b_bits = utils.buffer2bits(b_buffer);

        var res_buffer = [];
        for(let i=0; i<res.length; i++)
        {
            res_buffer.push(...utils.intToLEBuffer(res[i], 8));
        }
        var res_bits = utils.buffer2bits(res_buffer);

        let witness = await cir.calculateWitness({src1: a_bits, src2: b_bits});
        witness = witness.slice(1,129);
        assert.ok(res_bits.every((v, i)=> v == witness[i]));
    });
});
