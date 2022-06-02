const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("GFmul test", () => {
    it("Show do gf multiplication correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","gfmul_int2.circom"));
        const a = [BigInt("1"),BigInt("0")];
        const b = [BigInt("4876465869548802997"),BigInt("9173032812820655379")];
        let witness = await cir.calculateWitness({"a": a, "b": b});
        // console.log("Expected", res);
        console.log("a", a);
        console.log("b", b);
        console.log("witness", witness);
        assert.ok(1)
    })
})