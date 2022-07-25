const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;
const Module = require("./module.js");
const utils = require("./utils");

describe("AES256 Key Expansion test", () => {
    it("Show do key expansion correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","aes_256_key_expansion_test.circom"));
        const ip = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        // let ks = [1, 0, 0, 0, 0, 0, 0, 0, 1667457891, 1667457891, 1667457891, 1667457891, 4227595259, 4227595259, 4227595259, 4227595259, 1819044974, 252645133, 1819044974, 252645133, 2374864172, 1987475159, 2374864172, 1987475159, 1649693778, 1834703711, 20395825, 238565436, 646613703, 1358756880, 3715199292, 2869364715, 2335609247, 3865955008, 3881500145, 3915564493, 941632634, 1759301738, 3048055126, 514500285, 4047781291, 388626283, 4034071194, 420597591, 3970082337, 2222880331, 835966749, 796488096, 290556712, 108559427, 4127946457, 4011506062, 855699512, 3078522483, 2259505518, 2849251534, 2592261087, 2633678748, 1794230597, 2246799563 ];
        var ks = [];
        const ks_len = 60;

        const ip_ptr = Module._malloc(ip.length * Uint8Array.BYTES_PER_ELEMENT);
        const ks_ptr = Module._malloc(ks_len * Uint32Array.BYTES_PER_ELEMENT);

        Module.HEAPU8.set(new Uint8Array(ip), ip_ptr/Uint8Array.BYTES_PER_ELEMENT);

        Module._AES_256_Key_Expansion(ip_ptr, ks_ptr);

        for(let i=0; i<ks_len; i++)
        {
            ks.push(Module.HEAPU32[ks_ptr/Uint32Array.BYTES_PER_ELEMENT + i]);
        }

        var ks_buffer = [];
        for(let i=0; i<ks_len; i++)
        {
            ks_buffer.push(...utils.intToLEBuffer(ks[i], 4));
        }
        var ks_bits = utils.buffer2bits(ks_buffer);
        
        let witness = await cir.calculateWitness({key: utils.buffer2bits(ip)});
        witness = witness.slice(1,1921);
        assert.ok(ks_bits.every((v, i)=> v == witness[i]));
    });
});
