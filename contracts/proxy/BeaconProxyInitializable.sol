// SPDX-License-Identifier: BUSL-1.1

// Based on OpenZeppelin's BeaconProxy.sol + added Initializability to allow cloning the proxy
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";

import "@openzeppelin/contracts/proxy/Proxy.sol";

contract BeaconProxyInitializable is
    Initializable,
    Proxy,
    ERC1967UpgradeUpgradeable
{
    function initialize(
        address beacon,
        bytes memory data
    ) public payable initializer {
        _upgradeBeaconToAndCall(beacon, data, false);

        ERC1967UpgradeUpgradeable.__ERC1967Upgrade_init();
    }

    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeaconUpgradeable(_getBeacon()).implementation();
    }

    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}
