// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";

import "./Common.sol";
import "./IAgreementFactory.sol";
import "./ERC1888/IERC1888.sol";

/// @title Agreement
/// @author Josip Bagaric
contract Agreement is ERC1155ReceiverUpgradeable, CommonConstants {
    address public agreementFactoryAddress;

    function setAgreementFactory(address _agreementFactory) public {
        require(
            agreementFactoryAddress == address(0),
            "agreement factory already set"
        );
        require(
            _agreementFactory != address(0),
            "cant use address zero as agreement factory"
        );

        agreementFactoryAddress = _agreementFactory;
    }

    function claim(
        address _registry,
        address _buyer,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _claimData
    ) public {
        require(
            msg.sender == agreementFactoryAddress,
            "Only the AgreementFactory can trigger the claiming"
        );
        IERC1888(_registry).safeTransferAndClaimFrom(
            address(this),
            _buyer,
            _id,
            _value,
            _data,
            _claimData
        );
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            agreementFactoryAddress != address(0),
            "AgreementFactory not set"
        );

        IAgreementFactory agreementFactory = IAgreementFactory(
            agreementFactoryAddress
        );
        agreementFactory.fillAgreement(value, id);

        return ERC1155_ACCEPTED;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            agreementFactoryAddress != address(0),
            "AgreementFactory not set"
        );

        IAgreementFactory agreementFactory = IAgreementFactory(
            agreementFactoryAddress
        );

        for (uint256 i = 0; i < values.length; i++) {
            agreementFactory.fillAgreement(values[i], ids[i]);
        }

        return ERC1155_BATCH_ACCEPTED;
    }

    function version() external pure virtual returns (string memory) {
        return "1.2.0";
    }
}
