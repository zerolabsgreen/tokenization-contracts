// SPDX-License-Identifier: BUSL-1.1
// Based on OpenZeppelin's UpgradeableBeacon.sol

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract UpgradeableBeaconUpgradeable is
    Initializable,
    IBeaconUpgradeable,
    OwnableUpgradeable
{
    address private _implementation;

    event Upgraded(address indexed implementation);

    function initialize(address implementation_) public initializer {
        _setImplementation(implementation_);

        OwnableUpgradeable.__Ownable_init();
    }

    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementation = newImplementation;
    }
}
