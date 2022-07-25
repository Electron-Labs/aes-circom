const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;


describe("Complete Decryption test", () => {
    it("Show do decryption correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","gcm_siv_dec_2_keys_test.circom"));
        const K1 = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const N = [3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const AAD = [];
        const CIPHERTEXT = [133,160,27,99,2,91,161,155,127,211,221,252,3,59,62,118,201,234,198,250,112,9,66,112,46,144,134,35,131,198,195,102];
        const MSG = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        let witness = await cir.calculateWitness({"K1": K1, "N":N, "AAD":AAD, "CIPHERTEXT":CIPHERTEXT});
        let success = witness[17];
        witness = witness.slice(1, 17);
        console.log("Expected", MSG);
        console.log("witness", witness);
        assert.ok(success==1);
        assert.ok(MSG.every((v, i)=> v == witness[i]));
    });
});