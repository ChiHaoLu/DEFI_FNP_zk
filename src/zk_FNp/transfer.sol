pragma solidity ^0.8.10; 

contract ra { 

    function tansfer(address input) view public returns(uint256){ 
        return uint256(uint160(input)); 
    } 

    function transfer_ans(uint input) view public returns(address){ 
        return address(uint160(input)); 
    } 
} 
