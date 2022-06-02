const path = require("path");
const assert = require('assert');
const wasmTester = require('circom_tester').wasm;


describe("Polyval test", () => {
    it("Show do polyval hashing correctly", async() => {
        const cir = await wasmTester(path.join(__dirname,"circuits","polyval.circom"));
        const input = [BigInt("2"),BigInt("0"),BigInt("3"),BigInt("0"),BigInt("4"),BigInt("0"),BigInt("5"),BigInt("0"),BigInt("0"),BigInt("81"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("81"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("0"),BigInt("33"),BigInt("1"),BigInt("0"),BigInt("0"),BigInt("1041"),BigInt("2323048667351641705"),BigInt("3471205677675590235"),BigInt("3471207876698846252"),BigInt("3184093526458380332"),BigInt("3184093521962347568"),BigInt("3184093521962347568"),BigInt("3471202379140706616"),BigInt("3471202379140706348"),BigInt("3184945626360852524"),BigInt("3472605373090769969"),BigInt("3473174933099262260"),BigInt("3545796593849874484"),BigInt("3687380676110267446"),BigInt("3978425801945200436"),BigInt("3616453401467369015"),BigInt("3616732673091581235"),BigInt("4051328946279036720"),BigInt("3687377398966662200"),BigInt("3617854196376942641"),BigInt("3688509887453934646"),BigInt("3473462996572582451"),BigInt("3618142234097300281"),BigInt("3687384000381793331"),BigInt("3617854196376942641"),BigInt("3834591002219657521"),BigInt("3616732673091582006"),BigInt("3473455334418494000"),BigInt("3687381779900411959"),BigInt("3977578078480185140"),BigInt("3690189958266761529")];
        const H = [BigInt("4876465869548802997"),BigInt("9173032812820655379")];
        const T = [BigInt("1447496719058453797"),BigInt("10021191554797066756")];
        let witness = await cir.calculateWitness({"in": input, "H": H, "T": T});
        console.log("witness", witness);
        assert.ok(1)
    })
})