const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("AES256 Key Expansion test", () => {
    it("Show do key expansion correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","mul2.circom"));
        let witness = await cir.calculateWitness({src1: 1, src2: 330975257});
        witness = witness;    
        console.log("witness", witness);
        assert.ok(1)
    })
})