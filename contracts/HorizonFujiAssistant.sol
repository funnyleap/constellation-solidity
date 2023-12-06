// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * @title Horizon String Converter
 * @author Barba
 * @notice This contract pourpose is to convert the API string into uint
 */
contract HorizonFujiAssistant is  OwnerIsCreator {

    /**
     * 
     * @param s Value received directly from the API.
     */
    function stringToUint(string memory s) public view onlyOwner returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        bool decimalFound = false;
        uint decimalPlace = 0;

        for (uint i = 0; i < b.length; i++) {
            if (b[i] == 'R' || b[i] == '$' || b[i] == '.' || b[i] == ' ') {
                continue;
            }

            if (b[i] == ',') {
                decimalFound = true;
                continue;
            }

            if (b[i] >= 0x30 && b[i] <= 0x39) { // ASCII '0' é 48
                result = result * 10 + (uint8(b[i]) - 48);
                if (decimalFound) {
                    decimalPlace++;
                    if (decimalPlace >= 2) {
                        break;
                    }
                }
            } else {
                revert("That is not a valid string");
            }
        }

        if (decimalPlace < 2) {
            if (decimalPlace == 1) {
                result *= 10;
            } else if (decimalPlace == 0 && decimalFound) {
                result *= 100;
            }
        }

        return result;
    }
}
