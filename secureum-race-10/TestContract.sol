// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract TestContract is Ownable {
    // @note takes an unsigned integer n, retrieves the last 64 bytes of the input data, decodes it as an unsigned integer, and adds it to n, returning the result.
    // @note ":" is slicing operation
    // @note decode = bytes => type (in thsi case uint)
    function Test1(uint n) external pure returns (uint) {
        return n + abi.decode(msg.data[msg.data.length - 64:], (uint)); // n + n
    }

    function Test2(uint n) public view returns (uint) {
        // @note It uses the abi.encodeCall function to create a byte array representing the function call.
        bytes memory fcall = abi.encodeCall(TestContract.Test1, (n));
        // @note abi.encodePacked function concatenates the encoded values without adding additional padding.
        bytes memory xtr = abi.encodePacked(uint(4), uint(5));
        bytes memory all = bytes.concat(fcall, xtr);
        (bool success, bytes memory data) = address(this).staticcall(all);
        return abi.decode(data, (uint));
    }

    type Nonce is uint256;
    struct Book {
        Nonce nonce;
    }

    function NextBookNonce(Book memory x) public pure {
        x.nonce = Nonce.wrap(Nonce.unwrap(x.nonce) + 3);
    }

    function Test3(uint n) public pure returns (uint) {
        Book memory bookIndex;
        bookIndex.nonce = Nonce.wrap(7);
        for (uint i = 0; i < n; i++) {
            NextBookNonce(bookIndex);
        }
        return Nonce.unwrap(bookIndex.nonce);
    }

    error ZeroAddress();
    error ZeroAmount();
    uint constant ZeroAddressFlag = 1;
    uint constant ZeroAmountFlag = 2;

    function process(address[] memory a, uint[] memory amount) public pure returns (uint) {
        uint error;
        uint total;
        for (uint i = 0; i < a.length; i++) {
            if (a[i] == address(0)) error |= ZeroAddressFlag;
            if (amount[i] == 0) error |= ZeroAmountFlag;
            total += amount[i];
        }
        if (error == ZeroAddressFlag) revert ZeroAddress();
        if (error == ZeroAmountFlag) revert ZeroAmount();
        return total;
    }

    function Test4(uint n) public pure returns (uint) {
        address[] memory a = new address[](n + 1);
        for (uint i = 0; i <= n; i++) {
            a[i] = address(uint160(i)); // @note zero address [0] = address(uint160(0))
        }
        uint[] memory amount = new uint[](n + 1);
        for (uint i = 0; i <= n; i++) {
            amount[i] = i; // @note zero amount [0] = 0
        }
        return process(a, amount);
    }

    uint public totalMinted;
    uint constant maxMinted = 100;
    event minted(uint totalMinted, uint currentMint);

    bool public paused;

    function pause() public {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function invariantCheck() public {
        if (totalMinted > maxMinted)
            // 0 > 100
            // this may never happen
            pause();
    }

    modifier checkInvariants() {
        require(!paused, 'Paused');
        _;
        invariantCheck();
        require(!paused, 'Paused');
    }

    function Test5(uint n) public checkInvariants {
        totalMinted += n; // n: 10 totalMinted: 10 -> n: 20 totalMinted: 30
    }
}
