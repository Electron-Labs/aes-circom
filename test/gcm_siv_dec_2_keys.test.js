const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;
const Module = require("./module.js");
const utils = require("./utils");

describe("Complete Decryption test", () => {
    it("Show do decryption correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","gcm_siv_dec_2_keys_test.circom"));
        const K1 = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const N = [3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        const AAD = [];
        const CT = [133,160,27,99,2,91,161,155,127,211,221,252,3,59,62,118,201,234,198,250,112,9,66,112,46,144,134,35,131,198,195,102];

        const MSG_length = CT.length-16;
        var MSG = [];

        const K1_ptr = Module._malloc(K1.length * Uint8Array.BYTES_PER_ELEMENT);
        const N_ptr = Module._malloc(N.length * Uint8Array.BYTES_PER_ELEMENT);
        const AAD_ptr = Module._malloc(AAD.length * Uint8Array.BYTES_PER_ELEMENT);
        const MSG_ptr = Module._malloc(MSG_length * Uint8Array.BYTES_PER_ELEMENT);
        const CT_ptr = Module._malloc(MSG_length * Uint8Array.BYTES_PER_ELEMENT);
        const TAG_ptr = Module._malloc(16 * Uint8Array.BYTES_PER_ELEMENT);

        Module.HEAPU8.set(new Uint8Array(K1), K1_ptr/Uint8Array.BYTES_PER_ELEMENT);
        Module.HEAPU8.set(new Uint8Array(N), N_ptr/Uint8Array.BYTES_PER_ELEMENT);
        Module.HEAPU8.set(new Uint8Array(AAD), AAD_ptr/Uint8Array.BYTES_PER_ELEMENT);
        Module.HEAPU8.set(new Uint8Array(CT.slice(0, MSG_length)), CT_ptr/Uint8Array.BYTES_PER_ELEMENT);
        Module.HEAPU8.set(new Uint8Array(CT.slice(MSG_length, CT.length)), TAG_ptr/Uint8Array.BYTES_PER_ELEMENT);

        Module._GCM_SIV_DEC_2_Keys(MSG_ptr, TAG_ptr, K1_ptr, N_ptr, AAD_ptr, CT_ptr, BigInt(AAD.length), BigInt(MSG_length));

        for(let i=0; i<MSG_length; i++)
        {
            MSG.push(Module.HEAPU8[MSG_ptr/Uint8Array.BYTES_PER_ELEMENT + i]);
        }

        var K1_bits = utils.buffer2bits(K1);
        var N_bits = utils.buffer2bits(N);
        var AAD_bits = utils.buffer2bits(AAD);
        var CT_bits = utils.buffer2bits(CT);
        let witness = await cir.calculateWitness({"K1": K1_bits, "N": N_bits, "AAD": AAD_bits, "CT": CT_bits});
        let success = witness[129];
        witness = witness.slice(1, 129);
        assert.ok(success==1);
        assert.ok(utils.buffer2bits(MSG).every((v, i)=> v == witness[i]));
    });
});
