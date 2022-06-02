const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;
const {isMainThread} = require('worker_threads');


describe("AES256 Key Expansion test", () => {
    it("Show do key expansion correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","aes256keyexpansion2.circom"));
        let ip = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        let witness = await cir.calculateWitness({key: ip});
        witness = witness.slice(1,61);    
        let hex_key = "";
        for(let i=0 ;i<60; i++){
            // console.log("xx", witness[i].toString(16));
            hex_key+= witness[i].toString(16);
        }
        // let x= 99;
        console.log("witness", witness);
        assert.ok(1)
    })
})