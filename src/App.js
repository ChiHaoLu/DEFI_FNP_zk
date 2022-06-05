import React, { useState } from 'react';
import jsonData from './zk_FNp/proof.json';
let Web3 = require("web3");

const proof = JSON.parse(JSON.stringify(jsonData));
const abi = [
  {
    "inputs": [
      {
        "components": [
          {
            "components": [
              {
                "internalType": "uint256",
                "name": "X",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "Y",
                "type": "uint256"
              }
            ],
            "internalType": "struct Pairing.G1Point",
            "name": "a",
            "type": "tuple"
          },
          {
            "components": [
              {
                "internalType": "uint256[2]",
                "name": "X",
                "type": "uint256[2]"
              },
              {
                "internalType": "uint256[2]",
                "name": "Y",
                "type": "uint256[2]"
              }
            ],
            "internalType": "struct Pairing.G2Point",
            "name": "b",
            "type": "tuple"
          },
          {
            "components": [
              {
                "internalType": "uint256",
                "name": "X",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "Y",
                "type": "uint256"
              }
            ],
            "internalType": "struct Pairing.G1Point",
            "name": "c",
            "type": "tuple"
          }
        ],
        "internalType": "struct Verifier.Proof",
        "name": "proof",
        "type": "tuple"
      },
      {
        "internalType": "uint256[2]",
        "name": "input",
        "type": "uint256[2]"
      }
    ],
    "name": "verifyTx",
    "outputs": [
      {
        "internalType": "bool",
        "name": "r",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "isDone",
    "outputs": [
      {
        "internalType": "bool",
        "name": "r",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "retrieveStudents",
    "outputs": [
      {
        "internalType": "address[]",
        "name": "",
        "type": "address[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]

function App() {

  const web3 = new Web3(window.ethereum);
  
  const check = async () => {
    let user = await window.ethereum
      .request({ method: "eth_requestAccounts" })
      .catch((err) => {
        console.error(err);
      })
      
    let verifier = new web3.eth.Contract(abi, '0xe03e186D9772C68329C26d9CD659036adFFDC6c0', {
      from: user[0], // default from address
    });

    const c = await verifier.methods
      .isDone()
      .call({ from: user[0] })
      .then(function (res) {
        console.log(res);
      }).catch(function (err) {
        console.log(err);
      });
  }
  
  const verify = async () => {
    let user = await window.ethereum
      .request({ method: "eth_requestAccounts" })
      .catch((err) => {
        console.error(err);
      })
    let verifier = new web3.eth.Contract(abi, '0xe03e186D9772C68329C26d9CD659036adFFDC6c0', {
      from: user[0], // default from address
    });

    const v = await verifier.methods
      .verifyTx(proof.proof, proof.inputs)
      .send({ from: user[0], gas: 4400000 })
      .once("error", (err) => {
        console.log(err)
      }).then((receipt) => {
        console.log(receipt)
      })
  }

  return (
    <div>
      <button onClick={() => verify()}>Verify</button>
      <button onClick={() => check()}>Check the Result</button>
    </div>
  );
}

export default App;


