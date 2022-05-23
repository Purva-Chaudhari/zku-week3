// [bonus] unit test for bonus.circom
const chai = require("chai");
const buildPoseidon = require("circomlibjs").buildPoseidon;

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;

describe("BlackBox Simple Variation test", function () {
    this.timeout(100000000);

    it("Left Deflection case", async () => {
        const circuit = await wasm_tester("contracts/circuits/bonus.circom");
        await circuit.loadConstraints();

        const solution = [3, 3];
        const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32));
        let poseidonJs = await buildPoseidon();
        const solutionHash = ethers.BigNumber.from(
        poseidonJs.F.toObject(poseidonJs([salt, ...solution]))
        );

        const guess = 2;
        const direction = [1, 0]; // Up or Right

        const INPUT = {
            "guessLaser": guess,
            "guessUp": direction[0], 
            "guessRight": direction[1], 
            "deflectionLaser": 2,
            "leftDef": 1, 
            "rightDef": 0, 
            "upDef": 0, 
            "downDef": 0, 
            "absorb": 0, 
            "pubSolnHash" : solutionHash,
            "atomLoc1_x" : solution[0],
            "atomLoc1_y" : solution[1],
            "privSalt" : salt,
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(solutionHash)));
    });

    it("Absorption case", async () => {
        const circuit = await wasm_tester("contracts/circuits/bonus.circom");
        await circuit.loadConstraints();

        const solution = [3, 3];
        const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32));
        let poseidonJs = await buildPoseidon();
        const solutionHash = ethers.BigNumber.from(
        poseidonJs.F.toObject(poseidonJs([salt, ...solution]))
        );

        const guess = 3;
        const direction = [0, 1]; // Up or Right

        const INPUT = {
            "guessLaser": guess,
            "guessUp": direction[0], 
            "guessRight": direction[1], 
            "deflectionLaser": 0,
            "leftDef": 0, 
            "rightDef": 0, 
            "upDef": 0, 
            "downDef": 0, 
            "absorb": 1, 
            "pubSolnHash" : solutionHash,
            "atomLoc1_x" : solution[0],
            "atomLoc1_y" : solution[1],
            "privSalt" : salt,
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(solutionHash)));
    });

});