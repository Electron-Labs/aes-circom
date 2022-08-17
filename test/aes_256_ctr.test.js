const path = require("path");
const assert = require("assert");
const wasmTester = require("circom_tester").wasm;
const Module = require("./module.js");
const utils = require("./utils");

describe("AES256 CTR Test", () => {
    it("Show do ctr correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","aes_256_ctr_test.circom"));
        const inp = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const ctr = [469237865, 927770925, 1003210585, 3037346057];
        const ks = [1962153145, 3621906731, 3712678050, 3286144703, 1815899717, 1472326661, 507853, 584243966, 3479675375, 411453636, 3318526054, 101852889, 66427248, 1412724085, 1412680376, 1994461254, 2506053927, 2379813347, 1209377157, 1309116252, 741379642, 2013592399, 741814775, 1523982769, 1575071710, 3493379645, 2553094072, 3593115876, 3671443539, 2731619100, 2397438699, 3559924570, 3819547632, 865146317, 2881227381, 2107019921, 625313746, 2274669774, 158512677, 3712128383, 828934090, 49910279, 2839910514, 3570600675, 1831067843, 3937883149, 3821396520, 1049065303, 1792708639, 1747124760, 3244726890, 364220553, 888569956, 3728856169, 1032074817, 50544918, 765586396, 1166207428, 2229564334, 2438062887];
        // let out = [9, 242, 12, 138, 154, 49, 246, 103, 82, 220, 171, 230, 66, 190, 161, 34, 194, 217, 143, 74, 232, 198, 247, 142, 31, 239, 78, 9, 43, 131, 176, 51, 126, 4, 9, 235, 124, 136, 4, 94, 182, 24, 67, 250, 46, 169, 88, 46, 140, 25, 66, 28, 225, 136, 91, 165, 56, 130, 219, 18, 25, 107, 119, 165, 251, 194, 240, 55, 93, 253, 55, 68, 168, 10, 9, 255, 138, 134, 154, 91, 119, 66, 182, 183, 14, 62, 154, 193, 49, 217, 29, 105, 228, 203, 120, 217, 249, 227, 78, 184, 69, 17, 120, 15, 120, 118, 38, 38, 130, 204, 135, 108, 76, 169, 27, 250, 250, 158, 176, 32, 167, 161, 246, 168, 219, 234, 154, 130, 225, 231, 81, 229, 80, 143, 247, 146, 209, 136, 242, 218, 72, 32, 228, 205, 27, 120, 23, 21, 106, 173, 223, 81, 98, 103, 195, 29, 103, 49, 117, 105, 79, 219, 94, 170, 78, 112, 10, 207, 106, 104, 1, 202, 145, 161, 47, 74, 207, 141, 243, 71, 239, 134, 184, 132, 236, 29, 124, 55, 15, 150, 202, 31, 206, 69, 210, 53, 235, 14, 96, 0, 65, 66, 220, 121, 227, 236, 112, 68, 35, 120, 118, 34, 146, 112, 2, 91, 251, 47, 74, 138, 84, 17, 108, 109, 189, 216, 202, 15, 20, 145, 185, 203, 185, 75, 19, 125, 144, 12, 53, 153, 89, 152, 11, 88, 89, 128, 34, 153, 2, 180, 112, 146, 149, 131, 162, 114]; 
        var out = [];
        const out_len = inp.length;
        
        const inp_ptr = Module._malloc(inp.length * Uint8Array.BYTES_PER_ELEMENT);
        const ctr_ptr = Module._malloc(ctr.length * Uint32Array.BYTES_PER_ELEMENT);
        const ks_ptr = Module._malloc(ks.length * Uint32Array.BYTES_PER_ELEMENT);
        const out_ptr = Module._malloc(out_len * Uint8Array.BYTES_PER_ELEMENT);

        Module.HEAPU8.set(new Uint8Array(inp), inp_ptr/Uint8Array.BYTES_PER_ELEMENT);
        Module.HEAPU32.set(new Uint32Array(ctr), ctr_ptr/Uint32Array.BYTES_PER_ELEMENT);
        Module.HEAPU32.set(new Uint32Array(ks), ks_ptr/Uint32Array.BYTES_PER_ELEMENT);

        Module._AES_256_CTR(out_ptr, inp_ptr, ctr_ptr, inp.length, ks_ptr);

        for(let i=0; i<out_len; i++)
        {
            out.push(Module.HEAPU8[out_ptr/Uint8Array.BYTES_PER_ELEMENT + i]);
        }

        var ks_buffer = [];
        for(let i=0; i<ks.length; i++)
        {
            ks_buffer.push(...utils.intToLEBuffer(ks[i], 4));
        }
        var ks_bits = utils.buffer2bits(ks_buffer);
		
        var ctr_buffer = [];
        for(let i=0; i<ctr.length; i++)
        {
            ctr_buffer.push(...utils.intToLEBuffer(ctr[i], 4));
        }
        var ctr_bits = utils.buffer2bits(ctr_buffer);

        let witness = await cir.calculateWitness({"ks":ks_bits, "in":utils.buffer2bits(inp), "ctr":ctr_bits});
        witness = witness.slice(1,129);
		
        assert.ok(utils.buffer2bits(out).every((v, i)=> v == witness[i]));
    });
});
