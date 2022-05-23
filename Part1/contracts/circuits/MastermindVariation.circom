pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

/* Implementation of Mastermind variation 6 from the link
 i.e. Super Mastermind (a.k.a. Deluxe Mastermind; a.k.a. Advanced Mastermind) 
 This version has 8 colors and 5 holes 
 In this variation the colors are unique, For making the game challenging
 repeatation of colors can be included and constraint check condition from 
 line 58 to 69 can be removed
*/

template MastermindVariation() {
    // Public inputs
    signal input pubGuess_color1;
    signal input pubGuess_color2;
    signal input pubGuess_color3;
    signal input pubGuess_color4;
    signal input pubGuess_color5;
    signal input pubNumRedPegs;
    signal input pubNumWhitePegs;
    signal input pubSolnHash;

    // Private inputs
    signal input privSoln_color1;
    signal input privSoln_color2;
    signal input privSoln_color3;
    signal input privSoln_color4;
    signal input privSoln_color5;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[5] = [pubGuess_color1, pubGuess_color2, pubGuess_color3, pubGuess_color4, pubGuess_color5];
    var soln[5] = [privSoln_color1, privSoln_color2, privSoln_color3, privSoln_color4, privSoln_color5];
    var j = 0;
    var k = 0;
    component lessThan[10];
    component equalGuess[10];
    component equalSoln[10];
    var equalIdx = 0;

    // Create a constraint that the solution and guess colors are all less than 8.
    for (j=0; j<5; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 8;
        lessThan[j].out === 1;
        lessThan[j+5] = LessThan(4);
        lessThan[j+5].in[0] <== soln[j];
        lessThan[j+5].in[1] <== 8;
        lessThan[j+5].out === 1;
        for (k=j+1; k<5; k++) {
            // Create a constraint that the solution and guess colors are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }

    // Count redPegs & whitePegs
    var redPegs = 0;
    var whitePegs = 0;
    component equalPegs[25];

    for (j=0; j<5; j++) {
        for (k=0; k<5; k++) {
            equalPegs[5*j+k] = IsEqual();
            equalPegs[5*j+k].in[0] <== soln[j];
            equalPegs[5*j+k].in[1] <== guess[k];
            whitePegs += equalPegs[5*j+k].out;
            if (j == k) {
                redPegs += equalPegs[5*j+k].out;
                whitePegs -= equalPegs[5*j+k].out;
            }
        }
    }

    // Create a constraint around the number of redPegs
    component equalRedPegs = IsEqual();
    equalRedPegs.in[0] <== pubNumRedPegs;
    equalRedPegs.in[1] <== redPegs;
    equalRedPegs.out === 1;
    
    // Create a constraint around the number of whitePegs
    component equalWhitePegs = IsEqual();
    equalWhitePegs.in[0] <== pubNumWhitePegs;
    equalWhitePegs.in[1] <== whitePegs;
    equalWhitePegs.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(6);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSoln_color1;
    poseidon.inputs[2] <== privSoln_color2;
    poseidon.inputs[3] <== privSoln_color3;
    poseidon.inputs[4] <== privSoln_color4;
    poseidon.inputs[5] <== privSoln_color5;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
 }

 component main {public [pubGuess_color1, pubGuess_color2, pubGuess_color3, pubGuess_color4, pubGuess_color5, pubNumRedPegs, pubNumWhitePegs, pubSolnHash]} = MastermindVariation();
// template MastermindVariation() {

// }

 //component main = MastermindVariation();