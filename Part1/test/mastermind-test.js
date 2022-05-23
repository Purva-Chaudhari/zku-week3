//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const chai = require("chai");
const buildPoseidon = require("circomlibjs").buildPoseidon;

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;

function calRWPegs (guess, solution) {
    const redPegs = solution.filter((sol, i) => {
        return sol === guess[i];
      }).length;
    
      const whitePegs = solution.filter((sol, i) => {
        return sol !== guess[i] && guess.some((g) => g === sol);
      }).length;
    
      return [redPegs, whitePegs];
}

describe("Super Mastermind Variation test", function () {
    this.timeout(100000000);

    it("2 RedPeg and 1 White Peg", async () => {
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();

        const solution = [2, 3, 6, 4, 7];
        const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32));
        let poseidonJs = await buildPoseidon();
        const solutionHash = ethers.BigNumber.from(
        poseidonJs.F.toObject(poseidonJs([salt, ...solution]))
        );

        const guess = [2, 1, 4, 5, 7];

        const rwpegs = calRWPegs(guess, solution)

        const INPUT = {
            "pubGuess_color1": guess[0],
            "pubGuess_color2": guess[1],
            "pubGuess_color3": guess[2],
            "pubGuess_color4": guess[3],
            "pubGuess_color5": guess[4],
            "pubNumRedPegs": rwpegs[0],
            "pubNumWhitePegs": rwpegs[1],
            "pubSolnHash" : solutionHash,
            "privSoln_color1" : solution[0],
            "privSoln_color2" : solution[1],
            "privSoln_color3" : solution[2],
            "privSoln_color4" : solution[3],
            "privSoln_color5" : solution[4],
            "privSalt" : salt,
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(solutionHash)));
    });

    it("Correct Guess", async () => {
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();

        const solution = [2, 3, 6, 4, 7];
        const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32));
        let poseidonJs = await buildPoseidon();
        const solutionHash = ethers.BigNumber.from(
        poseidonJs.F.toObject(poseidonJs([salt, ...solution]))
        );

        const guess = [2, 3, 6, 4, 7];

        const rwpegs = calRWPegs(guess, solution)

        const INPUT = {
            "pubGuess_color1": guess[0],
            "pubGuess_color2": guess[1],
            "pubGuess_color3": guess[2],
            "pubGuess_color4": guess[3],
            "pubGuess_color5": guess[4],
            "pubNumRedPegs": rwpegs[0],
            "pubNumWhitePegs": rwpegs[1],
            "pubSolnHash" : solutionHash,
            "privSoln_color1" : solution[0],
            "privSoln_color2" : solution[1],
            "privSoln_color3" : solution[2],
            "privSoln_color4" : solution[3],
            "privSoln_color5" : solution[4],
            "privSalt" : salt,
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(solutionHash)));
    });
});