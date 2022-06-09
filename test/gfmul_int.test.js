const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("GFmul test", () => {
    it("Show do gf multiplication correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","gfmul_int_test.circom"));
        const a = [BigInt("1"),BigInt("0")];
        const b = [BigInt("4876465869548802997"),BigInt("9173032812820655379")];
        const res = [BigInt("1447496719058453797"),BigInt("10021191554797066756")];
        let witness = await cir.calculateWitness({"a": a, "b": b});
        witness = witness.slice(1, 3);
        console.log("Expected", res);
        console.log("witness", witness);
        assert.ok(res.every((v, i)=> v == witness[i]));
    })
})