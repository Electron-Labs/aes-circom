const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;
const Module = require("./module.js");
const utils = require("./utils");

describe("AES256 Encrypt Test", () => {
    it("Show do encrypt correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","aes_256_encrypt_test.circom"));
        const inp = [0,3,0,0];
        const ks = [1,0,0,0,0,0,0,0,1667457891,1667457891,1667457891,1667457891,4227595259,4227595259,4227595259,4227595259,1819044974,252645133,1819044974,252645133,2374864172,1987475159,2374864172,1987475159,1649693778,1834703711,20395825,238565436,646613703,1358756880,3715199292,2869364715,2335609247,3865955008,3881500145,3915564493,941632634,1759301738,3048055126,514500285,4047781291,388626283,4034071194,420597591,3970082337,2222880331,835966749,796488096,290556712,108559427,4127946457,4011506062,855699512,3078522483,2259505518,2849251534,2592261087,2633678748,1794230597,2246799563];
        // let out = [700830645,1135390687,1000768515,2660855300];
        var out = [];
        const out_len = 4;

        const inp_ptr = Module._malloc(inp.length * Uint32Array.BYTES_PER_ELEMENT);
        const ks_ptr = Module._malloc(ks.length * Uint32Array.BYTES_PER_ELEMENT);
        const out_ptr = Module._malloc(out_len * Uint32Array.BYTES_PER_ELEMENT);

        Module.HEAPU32.set(new Uint32Array(inp), inp_ptr/Uint32Array.BYTES_PER_ELEMENT);
        Module.HEAPU32.set(new Uint32Array(ks), ks_ptr/Uint32Array.BYTES_PER_ELEMENT);

        Module._AES_256_Encrypt(out_ptr, inp_ptr, ks_ptr);

        for(let i=0; i<out_len; i++)
        {
            out.push(Module.HEAPU32[out_ptr/Uint32Array.BYTES_PER_ELEMENT + i]);
        }

        var ks_buffer = [];
        for(let i=0; i<ks.length; i++)
        {
            ks_buffer.push(...utils.intToLEBuffer(ks[i], 4));
        }
        var ks_bits = utils.buffer2bits(ks_buffer);

        var inp_buffer = [];
        for(let i=0; i<inp.length; i++)
        {
            inp_buffer.push(...utils.intToLEBuffer(inp[i], 4));
        }
        var inp_bits = utils.buffer2bits(inp_buffer);

        var out_buffer = [];
        for(let i=0; i<out.length; i++)
        {
            out_buffer.push(...utils.intToLEBuffer(out[i], 4));
        }
        var out_bits = utils.buffer2bits(out_buffer);

        let witness = await cir.calculateWitness({"ks":ks_bits, "in":inp_bits});
        witness = witness.slice(1,129);
		
        assert.ok(out_bits.every((v, i)=> v == witness[i]));
    });
});
