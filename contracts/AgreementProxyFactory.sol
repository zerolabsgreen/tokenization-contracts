// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./proxy/UpgradeableBeaconUpgradeable.sol";
import "./proxy/BeaconProxyInitializable.sol";
import "./Agreement.sol";
import "./IAgreementFactory.sol";

contract AgreementProxyFactory is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    address public beacon;
    address public cloneProxy;
    address public agreementFactory;

    modifier onlyAgreementFactory() {
        require(
            _msgSender() == agreementFactory,
            "can only be called by the agreement factory"
        );
        _;
    }

    function initialize(address _agreementFactoryAddress) public initializer {
        UpgradeableBeaconUpgradeable beaconContract = new UpgradeableBeaconUpgradeable();
        beaconContract.initialize(address(new Agreement()));

        agreementFactory = _agreementFactoryAddress;

        address agreementFactoryOwner = IAgreementFactory(
            _agreementFactoryAddress
        ).owner();
        beaconContract.transferOwnership(agreementFactoryOwner);

        beacon = address(beaconContract);
        cloneProxy = address(new BeaconProxyInitializable());

        UUPSUpgradeable.__UUPSUpgradeable_init();
        OwnableUpgradeable.__Ownable_init();

        transferOwnership(agreementFactoryOwner);
    }

    function createProxy(
        bytes32 salt,
        bytes memory data
    ) external onlyAgreementFactory returns (address proxyAddress) {
        proxyAddress = ClonesUpgradeable.cloneDeterministic(cloneProxy, salt);

        BeaconProxyInitializable(payable(proxyAddress)).initialize(
            beacon,
            data
        );
    }

    function predictAddresses(
        bytes32[] memory salts
    ) public view onlyAgreementFactory returns (address[] memory addresses) {
        addresses = new address[](salts.length);

        for (uint256 i = 0; i < salts.length; i++) {
            addresses[i] = ClonesUpgradeable.predictDeterministicAddress(
                cloneProxy,
                salts[i]
            );
        }
    }

    /// @notice Needed for OpenZeppelin contract upgradeability.
    /// @dev Allow only to the owner of the contract.
    function _authorizeUpgrade(address) internal override onlyOwner {
        // Allow only owner to authorize a smart contract upgrade
    }

    function version() external pure returns (string memory) {
        return "1.2.1";
    }
}
