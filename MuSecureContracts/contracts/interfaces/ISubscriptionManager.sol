// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ISubscriptionManager {
    
    enum SubscriptionTier {
        Free,    // Nivel 0: Gratuito - Servicios básicos
        Pro,     // Nivel 1: Profesional - Servicios mejorados  
        Gold     // Nivel 2: Oro - Servicios premium completos
    }

    struct Subscription {
        address user;           
        SubscriptionTier tier;  
        uint256 startDate;      
        uint256 endDate;        
        bool isActive;          
    }

    struct ServiceFeatures {
        bool metadataIPFS;          
        bool fingerprintOnchain;    
        bool audioIPFS;             
        bool permanentStorage;      
        uint256 maxFingerprintSize; 
    }


    event SubscriptionUpdated(
        address indexed user,   
        SubscriptionTier tier,  
        uint256 startDate,      
        uint256 endDate         
    );

    event TierFeaturesUpdated(
        SubscriptionTier tier,  
        ServiceFeatures features 
    );

    function setSubscription(
        address _user,             
        SubscriptionTier _tier,     
        uint256 _durationInDays     
    ) external;

    function getUserSubscription(address _user) external view returns (Subscription memory);

    function getTierFeatures(SubscriptionTier _tier) external view returns (ServiceFeatures memory);

    function canStoreAudioIPFS(address _user) external view returns (bool);

    function canUsePermanentStorage(address _user) external view returns (bool);

    function getMaxFingerprintSize(address _user) external view returns (uint256);

    function setTierFeatures(SubscriptionTier _tier, ServiceFeatures calldata _features) external;
}


