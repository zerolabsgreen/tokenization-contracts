// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./CertificateRegistryExtended.sol";

/// @title Batch Factory
/// @author Josip Bagaric
contract BatchFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Generator {
        string id;
        string name;
        string energySource;
        string region;
        string country;
        uint256 commissioningDate;
        uint256 capacity;
    }

    struct Batch {
        string redemptionStatement;
        string storagePointer;
    }

    CertificateRegistryExtended public registry;

    uint256 public topic;
    uint256 internal latestCertificateBatchId; // Unused

    mapping(uint256 => Batch) public batches;
    mapping(string => uint256) public redemptionStatementToBatch;

    // batchId => index => certificateId
    mapping(uint256 => mapping(uint256 => uint256)) public batchCertificates;
    // certificateId => isInvalid
    mapping(uint256 => bool) public certificateInvalid;

    event RedemptionStatementSet(
        bytes32 indexed batchId,
        string redemptionStatement,
        string storagePointer
    );
    event CertificateBatchMinted(
        bytes32 indexed batchId,
        uint256[] certificateIds
    );
    event CertificateInvalidated(uint256 certificateId, bool isValid);

    function initialize(uint256 _topic) public initializer {
        topic = _topic;
        OwnableUpgradeable.__Ownable_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();
    }

    function setRedemptionStatement(
        bytes32 _batchId,
        string memory _redemptionStatement,
        string memory _storagePointer
    ) public onlyOwner {
        uint256 batchId = uint256(_batchId);

        require(
            bytes(_redemptionStatement).length != 0,
            "Redemption statement should not be an empty string"
        );
        require(
            bytes(batches[batchId].redemptionStatement).length == 0,
            "Redemption statement already set for batch"
        );
        require(
            redemptionStatementToBatch[_redemptionStatement] == 0,
            "Redemption statement already used in another batch"
        );

        batches[batchId].redemptionStatement = _redemptionStatement;
        batches[batchId].storagePointer = _storagePointer;

        redemptionStatementToBatch[_redemptionStatement] = batchId;

        emit RedemptionStatementSet(
            _batchId,
            _redemptionStatement,
            _storagePointer
        );
    }

    function mint(
        bytes32 _batchId,
        address[] memory _to,
        uint256[] memory _amounts,
        bytes[] memory _metadata
    ) public onlyOwner {
        uint256 batchId = uint256(_batchId);

        require(address(registry) != address(0), "Registry address not set");
        require(
            bytes(batches[batchId].redemptionStatement).length != 0,
            "Redemption statement not set for batch"
        );

        uint256[] memory topics = new uint256[](_to.length);
        bytes[] memory validityData = new bytes[](_to.length);

        for (uint256 i = 0; i < _to.length; i++) {
            topics[i] = topic;
            validityData[i] = abi.encodeWithSignature(
                "isValid(bytes32,uint256)",
                [batchId, i]
            );
        }

        uint256[] memory ids = registry.batchIssueMultiple(
            _to,
            validityData,
            topics,
            _amounts,
            _metadata
        );

        for (uint256 i = 0; i < ids.length; i++) {
            batchCertificates[batchId][i] = ids[i];
        }

        emit CertificateBatchMinted(_batchId, ids);
    }

    function setRegistry(address _registryAddress) public onlyOwner {
        require(address(registry) == address(0), "Registry already set");
        registry = CertificateRegistryExtended(_registryAddress);
    }

    function setInvalid(
        uint256 _certificateId,
        bool _isInvalid
    ) external onlyOwner {
        require(
            certificateInvalid[_certificateId] != _isInvalid,
            "Already in that invalidation state"
        );

        certificateInvalid[_certificateId] = _isInvalid;

        emit CertificateInvalidated(_certificateId, _isInvalid);
    }

    function getBatch(bytes32 _batchId) public view returns (Batch memory) {
        return batches[uint256(_batchId)];
    }

    /// @notice Validation for certificates.
    /// @dev Used by other contracts to validate a specific certificate.
    function isValid(
        bytes32 _batchId,
        uint256 _certificateIndex
    ) external view returns (bool) {
        return isValid(uint256(_batchId), _certificateIndex);
    }

    /// @notice Needed for backwards compatibility with the old uint256 batch ID format
    function isValid(
        uint256 _batchId,
        uint256 _certificateIndex
    ) public view returns (bool) {
        uint256 certificateId = batchCertificates[_batchId][_certificateIndex];
        return !certificateInvalid[certificateId];
    }

    function version() external pure returns (string memory) {
        return "1.2.1";
    }

    /// @notice Needed for OpenZeppelin contract upgradeability.
    /// @dev Allow only to the owner of the contract.
    function _authorizeUpgrade(address) internal override onlyOwner {
        // Allow only owner to authorize a smart contract upgrade
    }
}
