// [bonus] implement an example game from part d
pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template RangeProof(n) {
    assert(n <= 252);
    signal input in; // this is the number to be proved inside the range
    signal input range[2]; // the two elements should be the range, i.e. [lower bound, upper bound]
    signal output out;

    component low = LessEqThan(n);
    component high = GreaterEqThan(n);

    // [assignment] insert your code here
    low.in[0] <== in;
    low.in[1] <== range[1];

    high.in[0] <== in;
    high.in[1] <== range[0];

    out <== high.out*low.out;
}

/* BlackBox 1 atom approach
*/

template BlackBoxSimple() {
    // Public inputs
    signal input guessLaser;
    signal input guessUp;
    signal input guessRight;
    signal input deflectionLaser;
    signal input leftDef;
    signal input rightDef;
    signal input upDef;
    signal input downDef;
    signal input absorb;
    signal input pubSolnHash;

    // Private inputs
    signal input atomLoc1_x;
    signal input atomLoc1_y;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    // We have a 5x5 grid, therefore the following constraint checks that the solution 
    // and guess are both less than 5

    var atomCords[2] = [atomLoc1_x, atomLoc1_y];
    
    //5x5 grid has indices 0-4. Check if the atom location lies in the range
    component rangecheck[2];
    for (var i=0; i<2; i++) {
        rangecheck[i] = RangeProof(32);
        rangecheck[i].in <== atomCords[i];
        rangecheck[i].range[0] <== 0;
        rangecheck[i].range[1] <== 4;
        rangecheck[i].out === 1;
    }

    // check guess location lies in the range 0-4
    component rangecheckguess = RangeProof(8);
    rangecheckguess.in <== guessLaser;
    rangecheckguess.range[0] <== 0;
    rangecheckguess.range[1] <== 4;
    rangecheckguess.out === 1;

    // Guess has only one laser beam, i.e only one of the signals 
    // (guessUp, guessRight) is non zero.
    // Checking the above condition
    component checkSignals = IsEqual();
    checkSignals.in[0] <== guessUp*guessRight;
    checkSignals.in[1] <== 0;
    checkSignals.out === 1;

    // Following are the cases to check for deflections and asserting the deflections with atom location

    component atoms[8];
    for (var i=0; i<8; i++){
        atoms[i] = IsEqual();
    }

    signal upLeft;
    upLeft <== guessUp*leftDef;

    atoms[0].in[0] <== (guessLaser+1)*upLeft;
    atoms[0].in[1] <== atomLoc1_x*upLeft;
    atoms[0].out === 1;

    atoms[1].in[0] <== (deflectionLaser+1)*upLeft;
    atoms[1].in[1] <== atomLoc1_y*upLeft;
    atoms[1].out === 1;

    signal upRight;
    upRight <== guessUp*rightDef;

    atoms[2].in[0] <== (guessLaser-1)*upRight;
    atoms[2].in[1] <== atomLoc1_x*upRight;
    atoms[2].out === 1;

    atoms[3].in[0] <== (deflectionLaser+1)*upRight;
    atoms[3].in[1] <== atomLoc1_y*upRight;
    atoms[3].out === 1;

    signal rightDown;
    rightDown <== guessRight*downDef;

    atoms[4].in[0] <== (deflectionLaser+1)*rightDown;
    atoms[4].in[1] <== atomLoc1_x*rightDown;
    atoms[4].out === 1;

    atoms[5].in[0] <== (guessLaser+1)*rightDown;
    atoms[5].in[1] <== atomLoc1_y*rightDown;
    atoms[5].out === 1;

    signal rightUp;
    rightUp <== guessRight*upDef;

    atoms[6].in[0] <== (deflectionLaser+1)*rightUp;
    atoms[6].in[1] <== atomLoc1_x*rightUp;
    atoms[6].out === 1;

    atoms[7].in[0] <== (guessLaser-1)*rightUp;
    atoms[7].in[1] <== atomLoc1_y*rightUp;
    atoms[7].out === 1;

    component checkAbsorb[2];
    checkAbsorb[0] = IsEqual();
    checkAbsorb[1] = IsEqual();

    var abs = 0;
    checkAbsorb[0].in[0] <== guessLaser*guessUp;
    checkAbsorb[0].in[1] <== atomLoc1_x;
    abs = abs + checkAbsorb[0].out;

    checkAbsorb[1].in[0] <== guessLaser*guessRight;
    checkAbsorb[1].in[1] <== atomLoc1_y;
    abs = abs + checkAbsorb[1].out;

    absorb === abs;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(3);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== atomLoc1_x;
    poseidon.inputs[2] <== atomLoc1_y;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
 }

component main {public [guessLaser, guessUp, guessRight, leftDef, rightDef, upDef, downDef, absorb, pubSolnHash]} = BlackBoxSimple();