const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;
const Module = require('./module.js');


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

        let witness = await cir.calculateWitness({src1: a, src2: b});
        witness = witness.slice(1,3);
        console.log("Expected", res);    
        console.log("witness", witness);
        assert.ok(res.every((v, i)=> v == witness[i]));
    })
})