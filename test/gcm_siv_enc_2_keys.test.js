const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("Complete Encryption test", () => {
    it("Show do encryption correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","gcm_siv_enc_2_keys_test.circom"));
        const K1 = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const N = [3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const AAD = [];
        const MSG = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const CIPHERTEXT = [133,160,27,99,2,91,161,155,127,211,221,252,3,59,62,118,201,234,198,250,112,9,66,112,46,144,134,35,131,198,195,102];
        let witness = await cir.calculateWitness({"K1": K1, "N":N, "AAD":AAD, "MSG":MSG});
        witness = witness.slice(1, 33);
        console.log("Expected", CIPHERTEXT);
        console.log("witness", witness);
        assert.ok(CIPHERTEXT.every((v, i)=> v == witness[i]));
    })
})