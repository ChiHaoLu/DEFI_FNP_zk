// SPDX-License-Identifier: GPL-3.0
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x094d4193a76c7d6d9b7e5dce738cf66ff1250ccb9800522134deb5967e64a256), uint256(0x2785551a3c9c799abd0f3ffe32b2f4ae78fc489f954f827a901458f53c30f1d8));
        vk.beta = Pairing.G2Point([uint256(0x0dc9dad71eb5516617db523517bf3ed1d75f7c86d0806ea07f0eb433b5dfca98), uint256(0x0189cb6388d748faefc3b8249b24858676d8373e1afca20b9a873f1d661eebfd)], [uint256(0x116b916287a727fc0901c64c2dfd18bb7962691653d52ae4a6108440012770fe), uint256(0x269de3410c2893ec779daa96eb8ff00a9a655a62d32329ead800a354dccb16cc)]);
        vk.gamma = Pairing.G2Point([uint256(0x01b16907828cafa33b00753a63aeb56f8e5568c83102d4ee73478385bf0b34a6), uint256(0x25965b943c57ce7fdf29b59922239e8a737638c9a5dc29b0b49a57f543727406)], [uint256(0x29d19f00ddfcc47648d64eb282a764400aed53555552d4aa1b096ddd6e383511), uint256(0x24979d073fde9a95940996435c71f03291de1b71920b345e652cbec4fff01972)]);
        vk.delta = Pairing.G2Point([uint256(0x187ced627c36df253c20b12755f71c5585fbe9788d294e2a38f8d0c3a43c73be), uint256(0x2b5b90beab251b6fdb67ae4cc7f798fb13259ed5adf06a2cddf1b5f203bd3e30)], [uint256(0x300ebc52131054e9765ae82b55b6735aef00c72f7738819b0ad798b5c18e4251), uint256(0x2ff5e315a8786a08a2c0f433aff6f145c622752b4e7902526a22863ff96a2143)]);
        vk.gamma_abc = new Pairing.G1Point[](3);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2230f8bab26459b422fbec933a1b6d81bf5a95628f37fc824638e54ba34e231c), uint256(0x2821493af1ab3e94fd4f6e765e6e58459b839f6d45c903fb64ac81d2ccc60fee));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x26881dbe4e18bc411abd482d087486d433b4b4199701e0a2c2b9ef1f3a22edfb), uint256(0x03919bce2ffcccbc7f5f59a148317c1ed15ae4e59e79a7cf003e2d3099f221d3));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x302a442605e3efdcd3017560e5d768681b92a71efefb93ee0e1b027c06c5f3c8), uint256(0x2586b81b35fe439f54743657fdcbf8300cdeb9dfc618babf083832d1d2dc9b11));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }

    mapping(address => bool) studentStatus;
    address[] studentList;

    function verifyTx(
            Proof memory proof, uint[2] memory input
        ) public returns (bool r) {
        uint[] memory inputValues = new uint[](2);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }

        address student = address(uint160(inputValues[0]));
        require(msg.sender == student);

        if (verify(inputValues, proof) == 0) {
            if (!studentStatus[student]) {
                studentStatus[student] = true;
                studentList.push(student);
            }
            return true;
        } else {
            return false;
        }
    }

    modifier onlyTA() {
        require(msg.sender == address(0xD49EeDbE1287C7C8d7a1906477de4184e7988dBD)); // If it is incorrect here, it reverts.
        _;                              // Otherwise, it continues.
    } 

    function isDone() public view returns (bool r){
        return studentStatus[msg.sender];
    }

    function retrieveStudents() public view onlyTA returns (address[] memory) {
        return studentList;
    }
}
