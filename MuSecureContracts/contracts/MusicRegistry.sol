// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


pragma solidity ^0.8.19;

import "./interfaces/IMusicRegistry.sol";
import "./interfaces/ISubscriptionManager.sol";
import "./libraries/AudioFingerprint.sol";

/**
 * @title MusicRegistry
 * @dev Contrato principal para registrar y gestionar tracks musicales
 * @notice Permite a los usuarios registrar su música con diferentes niveles de almacenamiento
 */
 contract MusicRegistry is IMusicRegistry {
    
    uint256 private _trackCounter;
    mapping(uint256 => MusicTrack) public tracks;
    mapping(address => uint256[]) private _ownerTracks;
    
    mapping(bytes32 => bool) private _existingFingerprints;
    
    ISubscriptionManager public subscriptionManager;
    
    
    /**
     * @dev Verifica que el track exista
     * @param _trackId ID del track a verificar
     */
    modifier trackExists(uint256 _trackId) {
        require(tracks[_trackId].isRegistered, "Track does not exist");
        _; 
    }
    
    /**
     * @dev Verifica que el caller sea el owner del track
     * @param _trackId ID del track a verificar
     */
    modifier onlyTrackOwner(uint256 _trackId) {
        require(tracks[_trackId].owner == msg.sender, "Not track owner");
        _; 
    }
    
    /**
     * @dev Inicializa el contrato con la dirección del SubscriptionManager
     * @param _subscriptionManager Dirección del contrato de suscripciones
     */
    constructor(address _subscriptionManager) {
        require(_subscriptionManager != address(0x080A8C0a65f218267f730A0A72e09a110D92E08A), "Invalid subscription manager");
        
        subscriptionManager = ISubscriptionManager(_subscriptionManager);
        
        _trackCounter = 10;
    }
    
   
    /**
     * @dev Registra un nuevo track musical
     * @param _title Título del track
     * @param _artist Artista del track
     * @param _genre Género musical
     * @param _metadataIPFS Hash IPFS de los metadatos
     * @param _fingerprintHash Datos del fingerprint de audio
     * @return trackId ID único del track registrado
     */
    function registerTrack(
        string memory _title,
        string memory _artist,
        string memory _genre,
        string memory _metadataIPFS,
        bytes memory _fingerprintHash 
    ) external returns (uint256) {
    
        require(bytes(_title).length > 0, "Title cannot be empty");
       
        require(bytes(_artist).length > 0, "Artist cannot be empty");
        require(bytes(_metadataIPFS).length > 0, "Metadata IPFS hash cannot be empty");
        require(_fingerprintHash.length > 0, "Fingerprint cannot be empty");

        require(
            AudioFingerprint.isUnique(_fingerprintHash, _existingFingerprints),
            "Fingerprint already exists"
        );
        

        ISubscriptionManager.Subscription memory userSub = 
            subscriptionManager.getUserSubscription(msg.sender);
        
        
        require(userSub.isActive, "No active subscription");
        
        ISubscriptionManager.ServiceFeatures memory features = 
            subscriptionManager.getTierFeatures(userSub.tier);
        
        require(
            AudioFingerprint.isValidSize(_fingerprintHash, features.maxFingerprintSize),
            "Fingerprint too large for tier"
        );
        
       
        AudioFingerprint.registerFingerprint(_fingerprintHash, _existingFingerprints);

     
        StorageType storageType;
        if (features.permanentStorage) {
            
            storageType = StorageType.PermanentStorage;
        } else if (features.audioIPFS) {
           
            storageType = StorageType.AudioIPFS;
        } else {
           
            storageType = StorageType.MetadataOnly;
        }
        
      
        uint256 trackId = _trackCounter++;
        
    
        MusicTrack storage newTrack = tracks[trackId];
        newTrack.trackId = trackId;                   
        newTrack.owner = msg.sender;                 
        newTrack.title = _title;                     
        newTrack.artist = _artist;                    
        newTrack.genre = _genre;                     
        newTrack.metadataIPFS = _metadataIPFS;       
        newTrack.audioIPFS = "";                     
        newTrack.permanentStorage = "";               
        newTrack.fingerprintHash = _fingerprintHash;  
        newTrack.timestamp = block.timestamp;        
        newTrack.storageType = storageType;           
        newTrack.isRegistered = true;                
        
        
        _ownerTracks[msg.sender].push(trackId);
        
        emit TrackRegistered(
            trackId,                // ID del track registrado
            msg.sender,             // Dirección del propietario
            _title,                 // Título del track
            storageType,            // Tipo de almacenamiento usado
            block.timestamp         // Momento del registro
        );
        return trackId;
    }
    
    /**
     * @dev Mejora el almacenamiento de un track existente
     * @param _trackId ID del track a mejorar
     * @param _audioIPFS Hash IPFS del audio (para tier Pro)
     * @param _permanentStorage Hash de almacenamiento permanente (para tier Gold)
     */
    function upgradeTrackStorage(
        uint256 _trackId,
        string memory _audioIPFS,
        string memory _permanentStorage
    ) external trackExists(_trackId) onlyTrackOwner(_trackId) {
        MusicTrack storage track = tracks[_trackId];
        
        ISubscriptionManager.Subscription memory userSub = 
            subscriptionManager.getUserSubscription(msg.sender);
        
        require(userSub.isActive, "No active subscription");
        
        ISubscriptionManager.ServiceFeatures memory features = 
            subscriptionManager.getTierFeatures(userSub.tier);
        
        if (features.audioIPFS && bytes(_audioIPFS).length > 0) {
            track.audioIPFS = _audioIPFS;
        }
        
        if (features.permanentStorage && bytes(_permanentStorage).length > 0) {
            track.permanentStorage = _permanentStorage;
        }
        
        if (features.permanentStorage) {
            track.storageType = StorageType.PermanentStorage;
        } else if (features.audioIPFS) {
            track.storageType = StorageType.AudioIPFS;
        }
        
        emit AudioStorageUpdated(_trackId, _audioIPFS, _permanentStorage);
    }
    
    /**
     * @dev Transfiere la propiedad de un track a otra dirección
     * @param _trackId ID del track a transferir
     * @param _newOwner Nueva dirección del propietario
     */
    function transferOwnership(
        uint256 _trackId, 
        address _newOwner
    ) external trackExists(_trackId) onlyTrackOwner(_trackId) {
        require(_newOwner != address(0), "Invalid new owner");
        
        require(_newOwner != msg.sender, "Cannot transfer to self");
        
        MusicTrack storage track = tracks[_trackId];
        
        address previousOwner = track.owner;
        
       
        track.owner = _newOwner;
        
        uint256[] storage previousOwnerTracks = _ownerTracks[previousOwner];
        for (uint256 i = 0; i < previousOwnerTracks.length; i++) {
            if (previousOwnerTracks[i] == _trackId) {
            
                previousOwnerTracks[i] = previousOwnerTracks[previousOwnerTracks.length - 1];
                previousOwnerTracks.pop();
                break;
            }
        }
        
        _ownerTracks[_newOwner].push(_trackId);
        
        emit OwnershipTransferred(_trackId, previousOwner, _newOwner);
    }
function getTrack(uint256 _trackId) 
    external 
    view 
    override 
    trackExists(_trackId) 
    returns (MusicTrack memory) 
{
    return tracks[_trackId];
}


function verifyOwnership(uint256 _trackId, address _claimant) 
    external 
    view 
    override 
    trackExists(_trackId) 
    returns (bool) 
{
    return tracks[_trackId].owner == _claimant;
}
function getTracksByOwner(address _owner) 
    external 
    view 
    returns (uint256[] memory) 
{
    return _ownerTracks[_owner];
}

function getTotalTracks() external view returns (uint256) {
    return _trackCounter - 1;
}
} 