const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;
const {isMainThread} = require('worker_threads');


describe("AES256 Key Expansion test", () => {
    it("Show do key expansion correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","aes_256_key_expansion_test.circom"));
        let ip = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        let ks = [1, 0, 0, 0, 0, 0, 0, 0, 1667457891, 1667457891, 1667457891, 1667457891, 4227595259, 4227595259, 4227595259, 4227595259, 1819044974, 252645133, 1819044974, 252645133, 2374864172, 1987475159, 2374864172, 1987475159, 1649693778, 1834703711, 20395825, 238565436, 646613703, 1358756880, 3715199292, 2869364715, 2335609247, 3865955008, 3881500145, 3915564493, 941632634, 1759301738, 3048055126, 514500285, 4047781291, 388626283, 4034071194, 420597591, 3970082337, 2222880331, 835966749, 796488096, 290556712, 108559427, 4127946457, 4011506062, 855699512, 3078522483, 2259505518, 2849251534, 2592261087, 2633678748, 1794230597, 2246799563 ];
        let witness = await cir.calculateWitness({key: ip});
        witness = witness.slice(1,61);    
        console.log("Expected", ks);
        console.log("witness", witness);
        assert.ok(ks.every((v, i)=> v == witness[i]));
    })
})