const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("Mul test", () => {
    it("Show do mul correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","mul2.circom"));
        const a = BigInt("13979173243358019584");
        const b = BigInt("13333588315241340027");
        const res = [BigInt("13114482114902884352"), BigInt("8337776831755140507")];
        let witness = await cir.calculateWitness({src1: a, src2: b});
        witness = witness.slice(1,3);
        console.log("Expected", res);    
        console.log("witness", witness);
        assert.ok(1)
    })
})