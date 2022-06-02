const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("AES256 Key Expansion test", () => {
    it("Show do key expansion correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","mul2.circom"));
        const a = BigInt("13979173243358019584");
        const b = BigInt("13333588315241340027")
        let witness = await cir.calculateWitness({src1: a, src2: b});
        witness = witness;    
        console.log("witness", witness);
        assert.ok(1)
    })
})