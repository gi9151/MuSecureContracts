// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMusicRegistry {
    
    enum StorageType {
        MetadataOnly,    // Nivel 0: Solo metadatos (Free tier)
        AudioIPFS,       // Nivel 1: Audio en IPFS (Pro tier)  
        PermanentStorage // Nivel 2: Almacenamiento permanente (Gold tier)
    }

    struct MusicTrack {
        uint256 trackId;           
        address owner;             
        string title;              
        string artist;             
        string genre;              
        string metadataIPFS;       
        string audioIPFS;         
        string permanentStorage;   
        bytes fingerprintHash;     
        uint256 timestamp;        
        StorageType storageType;   
        bool isRegistered;         
    }

    event TrackRegistered(
        uint256 indexed trackId,   
        address indexed owner,    
        string title,              
        StorageType storageType,   
        uint256 timestamp          
    );

    event AudioStorageUpdated(
        uint256 indexed trackId,       
        string audioIPFS,              
        string permanentStorage        
    );

    event OwnershipTransferred(
        uint256 indexed trackId,       
        address indexed previousOwner, 
        address indexed newOwner       
    );

    function registerTrack(
        string memory _title,          
        string memory _artist,         
        string memory _genre,         
        string memory _metadataIPFS,   
        bytes memory _fingerprintHash 
    ) external returns (uint256);      

    function upgradeTrackStorage(
        uint256 _trackId,             
        string memory _audioIPFS,      
        string memory _permanentStorage 
    ) external;

    function getTrack(uint256 _trackId) external view returns (MusicTrack memory);
    
    function transferOwnership(uint256 _trackId, address _newOwner) external;

    function verifyOwnership(uint256 _trackId, address _claimant) external view returns (bool);
     
    function getTracksByOwner(address _owner) external view returns (uint256[] memory);
}