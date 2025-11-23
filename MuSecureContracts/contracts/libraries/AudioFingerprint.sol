// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library AudioFingerprint {

    struct Fingerprint {
        bytes fingerprintData; 
        uint256 creationTime;   
        uint256 size;           
    }


    function isUnique(
        bytes memory _fingerprintData,           
        mapping(bytes32 => bool) storage _existingFingerprints // Mapa de fingerprints existentes
    ) internal view returns (bool) {
        bytes32 fingerprintHash = keccak256(_fingerprintData);
        return !_existingFingerprints[fingerprintHash];
    }

    function registerFingerprint(
        bytes memory _fingerprintData,           
        mapping(bytes32 => bool) storage _existingFingerprints // Mapa donde guardar
    ) internal {

        require(_fingerprintData.length > 0, "Invalid fingerprint data");
        
        bytes32 fingerprintHash = keccak256(_fingerprintData);

        require(!_existingFingerprints[fingerprintHash], "Fingerprint already exists");

        _existingFingerprints[fingerprintHash] = true;
    }

    function isValidSize(
        bytes memory _fingerprintData, 
        uint256 _maxSize              
    ) internal pure returns (bool) {
        return _fingerprintData.length <= _maxSize;
    }
}