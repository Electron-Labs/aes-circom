const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;
const Module = require("./module.js");


describe("Polyval test", () => {
    it("Show do polyval hashing correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","polyval_test.circom"));
        const input = [BigInt("1"),BigInt("0"),BigInt("2"),BigInt("0"),BigInt("3"),BigInt("0"),BigInt("4"),BigInt("0")];
        const H = [BigInt("4876465869548802997"),BigInt("9173032812820655379")];
        const T = [BigInt("0"),BigInt("0")];
        // const result = [BigInt("13221735031628986036"),BigInt("7104869591649800966")];
        var result = [];
        const result_len = 2;

        const input_ptr = Module._malloc(input.length * BigUint64Array.BYTES_PER_ELEMENT);
        const H_ptr = Module._malloc(H.length * BigUint64Array.BYTES_PER_ELEMENT);
        const result_ptr = Module._malloc(T.length * BigUint64Array.BYTES_PER_ELEMENT);

        Module.HEAPU64.set(new BigUint64Array(input), input_ptr/BigUint64Array.BYTES_PER_ELEMENT);
        Module.HEAPU64.set(new BigUint64Array(H), H_ptr/BigUint64Array.BYTES_PER_ELEMENT);
        Module.HEAPU64.set(new BigUint64Array(T), result_ptr/BigUint64Array.BYTES_PER_ELEMENT);

        Module._POLYVAL(input_ptr, H_ptr, BigInt(input.length * BigInt64Array.BYTES_PER_ELEMENT), result_ptr);

        for(let i=0; i<result_len; i++)
        {
            result.push(BigInt(Module.HEAPU64[result_ptr/BigUint64Array.BYTES_PER_ELEMENT + i]));
        }

        let witness = await cir.calculateWitness({"in": input, "H": H, "T": T});
        witness = witness.slice(1, 3);
        console.log("Expected", result);
        console.log("witness", witness);
        assert.ok(result.every((v, i)=> v == witness[i]));
    });
});