// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

contract Scale {

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index)
        internal
        pure
        returns (uint8)
    {
        return uint8(data[index]);
    }

      // Convert bytes (big endian) to little endian format
    function bytesToLittleEndian(bytes memory arr)
        internal
        pure
        returns (uint256)
    {
        uint256 number;
        for(uint i = 0; i < arr.length; i++){
            number = number + uint(uint8(arr[i])) * (2 ** (8 * (arr.length - (i + 1))));
        }
        return number;
    }

     // Reverse an array of bytes in place
    function reverseBytes(bytes memory arr)
        internal
        pure
        returns(bytes memory)
    {
        for (uint i = 0; i < arr.length/2; i++) {
            bytes1 current = arr[i];
            uint256 otherIndex = arr.length - i - 1;
            arr[i] = arr[otherIndex];
            arr[otherIndex] = current;
        }
        return arr;
    }

    // Decoes a SCALE encoded uint256
    function decodeUint256(bytes memory data)
        public
        pure
        returns (uint256)
    {
        bytes memory reversed = reverseBytes(data);
        uint256 lEndian = bytesToLittleEndian(reversed);
        return lEndian;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data)
        public
        pure
        returns (uint256)
    {
        uint8 b = readByteAtIndex(data, 0);           // read the first byte
        uint8 mode = b & 3;                           // bitwise operation

        if (mode == 0) {                               // [0, 63]
            return b >> 2;                            // right shift to remove mode bits
        } else if (mode == 1) {                        // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1);      // read the second byte
            uint64 r = bb;                            // convert to uint64
            r <<= 6;                                  // multiply by * 2^6
            r += b >> 2;                              // right shift to remove mode bits
            return r;
        } else if (mode == 2) {                        // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1);      // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | uint32(b2) << 8;  // convert to little endian
            uint32 x2 = x1 | uint32(b3) << 16;
            uint32 x3 = x2 | uint32(b4) << 24;

            x3 >>= 2;                                 // remove the last 2 mode bits
            return uint256(x3);
        } else if (mode == 3) {                        // [1073741824, 4503599627370496]
            uint8 l = b >> 2;                         // remove mode bits
            require(l > 32, "Not supported: number cannot be greater than 32 bytes");
        } else {
            revert("Code should be unreachable");
        }
    }
}
