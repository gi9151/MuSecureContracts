// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ISubscriptionManager.sol";

/**
 * @title SubscriptionManager
 * @dev Gestiona los planes de suscripción Free/Pro/Gold y sus características
 */
contract SubscriptionManager is ISubscriptionManager {
   
    mapping(address => Subscription) public subscriptions;
    mapping(SubscriptionTier => ServiceFeatures) public tierFeatures;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _; 
    }

    constructor() {
        owner = msg.sender;
        _initializeTierFeatures();
    }

    /**
     * @dev Establece o actualiza una suscripción para un usuario
     * @param _user Dirección del usuario
     * @param _tier Nivel de suscripción (Free/Pro/Gold)
     * @param _durationInDays Duración en días
     */
    function setSubscription(
        address _user,
        SubscriptionTier _tier,
        uint256 _durationInDays
    ) external override {
        require(_user != address(0), "Invalid user address");
        require(_durationInDays > 0, "Duration must be positive");
        
        uint256 startDate = block.timestamp;
        uint256 endDate = startDate + (_durationInDays * 1 days);
        subscriptions[_user] = Subscription({
            user: _user,        
            tier: _tier,        
            startDate: startDate, 
            endDate: endDate,   
            isActive: true     
        });
        
        emit SubscriptionUpdated(_user, _tier, startDate, endDate);
    }
    
    /**
     * @dev Configura las características para un tier específico
     * @param _tier Nivel de suscripción
     * @param _features Características del tier
     */
    function setTierFeatures(
        SubscriptionTier _tier,
        ServiceFeatures calldata _features
    ) external onlyOwner {
        tierFeatures[_tier] = _features;
        
        emit TierFeaturesUpdated(_tier, _features);
    }

    /*
     * @dev Obtiene la suscripción de un usuario
     * @param _user Dirección del usuario
     * @return Subscription información de la suscripción
     */
    function getUserSubscription(address _user) 
        external 
        view 
        override 
        returns (Subscription memory) 
    {
        Subscription memory sub = subscriptions[_user];
        if (sub.isActive && block.timestamp > sub.endDate) {
            sub.isActive = false;
        }
        return sub;
    }
    
    /**
     * @dev Obtiene las características de un tier
     * @param _tier Nivel de suscripción
     * @return ServiceFeatures características del tier
     */
    function getTierFeatures(SubscriptionTier _tier) 
        external 
        view 
        override 
        returns (ServiceFeatures memory) 
    {
        // Retorna las características del nivel solicitado
        return tierFeatures[_tier];
    }
    
    /**
     * @dev Verifica si un usuario puede almacenar audio en IPFS
     * @param _user Dirección del usuario
     * @return true si puede almacenar audio
     */
    function canStoreAudioIPFS(address _user) 
        external 
        view 
        override 
        returns (bool) 
    {
        Subscription memory sub = subscriptions[_user];
        if (!sub.isActive || block.timestamp > sub.endDate) return false;
        ServiceFeatures memory features = tierFeatures[sub.tier];
        return features.audioIPFS;
    }
    
    /**
     * @dev Verifica si un usuario puede usar almacenamiento permanente
     * @param _user Dirección del usuario
     * @return true si puede usar almacenamiento permanente
     */
    function canUsePermanentStorage(address _user) 
        external 
        view 
        override 
        returns (bool) 
    {
        Subscription memory sub = subscriptions[_user];
        if (!sub.isActive || block.timestamp > sub.endDate) return false;
        ServiceFeatures memory features = tierFeatures[sub.tier];
        return features.permanentStorage;
    }
    
    /**
     * @dev Obtiene el tamaño máximo de fingerprint permitido para un usuario
     * @param _user Dirección del usuario
     * @return tamaño máximo en bytes
     */
    function getMaxFingerprintSize(address _user) 
        external 
        view 
        override 
        returns (uint256) 
    {
        Subscription memory sub = subscriptions[_user];
        if (!sub.isActive || block.timestamp > sub.endDate) return 0;
        ServiceFeatures memory features = tierFeatures[sub.tier];
        return features.maxFingerprintSize;
    }
    
    /**
     * @dev Inicializa las características por defecto de cada tier
     */
    function _initializeTierFeatures() internal {
        tierFeatures[SubscriptionTier.Free] = ServiceFeatures({
            metadataIPFS: true,     
            fingerprintOnchain: true, 
            audioIPFS: false,       
            permanentStorage: false, 
            maxFingerprintSize: 1024 
        });
        
        tierFeatures[SubscriptionTier.Pro] = ServiceFeatures({
            metadataIPFS: true,     
            fingerprintOnchain: true, 
            audioIPFS: true,        
            permanentStorage: false, 
            maxFingerprintSize: 10240 
        });
        
        tierFeatures[SubscriptionTier.Gold] = ServiceFeatures({
            metadataIPFS: true,     
            fingerprintOnchain: true, 
            audioIPFS: true,       
            permanentStorage: true, 
            maxFingerprintSize: 51200 
        });
    }
}
    