const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;
const Module = require('./module.js');


describe("GFmul test", () => {
    it("Show do gf multiplication correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","gfmul_int_test.circom"));
        const a = [BigInt("1"),BigInt("0")];
        const b = [BigInt("4876465869548802997"),BigInt("9173032812820655379")];
        // const res = [BigInt("1447496719058453797"),BigInt("10021191554797066756")];
        var res = []
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

        let witness = await cir.calculateWitness({"a": a, "b": b});
        witness = witness.slice(1, 3);
        console.log("Expected", res);
        console.log("witness", witness);
        assert.ok(res.every((v, i)=> v == witness[i]));
    })
})