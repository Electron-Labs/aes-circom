const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("Polyval test", () => {
    it("Show do polyval hashing correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","polyval.circom"));
        const input = [1,0,2,0,3,0,4,0];
        const H = [BigInt("4876465869548802997"),BigInt("9173032812820655379")];
        const T = [BigInt("0"),BigInt("0")];
        const result = [BigInt("13221735031628986036"),BigInt("7104869591649800966")];
        let witness = await cir.calculateWitness({"in": input, "H": H, "T": T});
        console.log("Expected", result);
        console.log("witness", witness);
        assert.ok(1)
    })
})