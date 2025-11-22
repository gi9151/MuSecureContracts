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
    
    