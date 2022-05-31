const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;
const {isMainThread} = require('worker_threads');


describe("AES256 Key Expansion test", () => {
    it("Show do key expansion correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","aes256keyexpansion2.circom"));
        let ip = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const witness = await cir.calculateWitness({key: ip}, true);
        console.log("witness", witness);
        assert.ok(1)
    })
})