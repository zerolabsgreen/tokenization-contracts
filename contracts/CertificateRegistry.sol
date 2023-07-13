// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ERC1888/IERC1888.sol";

/// @title Certificate Registry
/// @author Josip Bagaric
/// @notice Credits: A part of this codebase was copied from by Energy Web Foundation's Origin implementation
contract CertificateRegistry is
    Initializable,
    IERC1888,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    enum TransactionType {
        MINT,
        TRANSFER,
        CLAIM
    }

    // Storage for the Certificate structs
    mapping(uint256 => Certificate) public certificateStorage;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) public claimedBalances;

    // Topic -> Issuer
    mapping(uint256 => address) public issuers;

    // Incrementing nonce, used for generating certificate IDs
    uint256 internal _latestCertificateId;

    // DEPRECATED
    mapping(uint256 => mapping(string => bytes)) public externalMetadata;

    // certificateId => metadata
    mapping(uint256 => bytes) public certificateMetadata;

    event CertificateMetadataSet(uint256 _certificateId, bytes _metadata);

    event IssuerWhitelisted(address _issuer, uint256 indexed _topic);
    event IssuerBlacklisted(address _issuer, uint256 indexed _topic);

    function __CertificateRegistry_init(
        string memory _uri
    ) internal onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();
        ERC1155Upgradeable.__ERC1155_init(_uri);
    }

    /// @notice See {IERC1888-issue}.
    /// @dev `_to` cannot be the zero address.
    function issue(
        address _to,
        bytes calldata _validityData,
        uint256 _topic,
        uint256 _value,
        bytes calldata _data
    ) external override returns (uint256 id) {
        _isIssuer(_topic);
        _validate(_msgSender(), _validityData);

        id = ++_latestCertificateId;

        certificateStorage[id] = Certificate({
            topic: _topic,
            issuer: _msgSender(),
            validityData: _validityData,
            data: new bytes(0)
        });

        setMetadata(id, _data);

        ERC1155Upgradeable._mint(
            _to,
            id,
            _value,
            _methodSymbol(TransactionType.MINT)
        );

        emit IssuanceSingle(_msgSender(), _topic, id, _value);
    }

    /// @notice See {IERC1888-batchIssue}.
    /// @dev `_to` cannot be the zero address.
    /// @dev `_data`, `_values` and `_validityData` must have the same length.
    function batchIssue(
        address _to,
        bytes[] memory _validityData,
        uint256[] memory _topics,
        uint256[] memory _values,
        bytes[] memory _data
    ) external override returns (uint256[] memory ids) {
        ids = new uint256[](_values.length);

        address operator = _msgSender();

        for (uint256 i = 0; i < _values.length; i++) {
            ids[i] = i + _latestCertificateId + 1;
            _isIssuer(_topics[i]);
            _validate(operator, _validityData[i]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            certificateStorage[ids[i]] = Certificate({
                topic: _topics[i],
                issuer: operator,
                validityData: _validityData[i],
                data: new bytes(0)
            });

            setMetadata(ids[i], _data[i]);
        }

        _latestCertificateId = ids[ids.length - 1];

        ERC1155Upgradeable._mintBatch(
            _to,
            ids,
            _values,
            _methodSymbol(TransactionType.MINT)
        );

        emit IssuanceBatch(operator, _topics, ids, _values);
    }

    /// @notice See {IERC1888-safeTransferAndClaimFrom}.
    /// @dev `_to` cannot be the zero address.
    /// @dev `_from` has to have a balance above or equal `_value`.
    function safeTransferAndClaimFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _claimData
    ) external override {
        require(
            _from == _msgSender() ||
                ERC1155Upgradeable.isApprovedForAll(_from, _msgSender()),
            "not owner nor approved"
        );
        _beforeTokenTransfer(
            _msgSender(),
            _from,
            _to,
            _toDynamicArray(_id),
            _toDynamicArray(_value),
            _data
        );

        claimedBalances[_id][_to] += _value;

        _burn(_from, _id, _value);

        emit ClaimSingle(
            _from,
            _to,
            certificateStorage[_id].topic,
            _id,
            _value,
            _claimData
        ); // _claimSubject address ??
    }

    /// @notice See {IERC1888-safeBatchTransferAndClaimFrom}.
    /// @dev `_to` and `_from` cannot be the zero addresses.
    /// @dev `_from` has to have a balance above 0.
    function safeBatchTransferAndClaimFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes calldata _data, // Unused
        bytes[] memory _claimData
    ) external override {
        require(_ids.length > 0, "no certificates specified");
        require(
            _from == _msgSender() ||
                ERC1155Upgradeable.isApprovedForAll(_from, _msgSender()),
            "not owner nor approved"
        );

        uint256[] memory topics = new uint256[](_ids.length);

        for (uint256 i = 0; i < _ids.length; i++) {
            _beforeTokenTransfer(
                _msgSender(),
                _from,
                _to,
                _ids,
                _values,
                _data
            );
            topics[i] = certificateStorage[_ids[i]].topic;

            claimedBalances[_ids[i]][_to] += _values[i];
        }

        // Separated from the loop above for re-entrancy
        for (uint256 i = 0; i < _ids.length; i++) {
            _burn(_from, _ids[i], _values[i]);
        }

        emit ClaimBatch(_from, _to, topics, _ids, _values, _claimData);
    }

    /// @notice See {IERC1888-claimedBalanceOf}.
    function claimedBalanceOf(
        address _owner,
        uint256 _id
    ) external view override returns (uint256) {
        return claimedBalances[_id][_owner];
    }

    /// @notice See {IERC1888-claimedBalanceOfBatch}.
    function claimedBalanceOfBatch(
        address[] memory _owners,
        uint256[] memory _ids
    ) external view override returns (uint256[] memory) {
        uint256[] memory batchClaimBalances = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            batchClaimBalances[i] = this.claimedBalanceOf(_owners[i], _ids[i]);
        }

        return batchClaimBalances;
    }

    /// @notice See {IERC1888-getCertificate}.
    function getCertificate(
        uint256 _id
    )
        public
        view
        override
        returns (
            address issuer,
            uint256 topic,
            bytes memory validityCall,
            bytes memory data
        )
    {
        Certificate memory certificate = certificateStorage[_id];
        return (
            certificate.issuer,
            certificate.topic,
            certificate.validityData,
            certificateMetadata[_id]
        );
    }

    function setMetadata(uint256 _id, bytes memory _metadata) public {
        require(
            certificateStorage[_id].issuer != address(0),
            "certificate doesn't exist"
        );
        _isIssuer(certificateStorage[_id].topic);
        require(
            certificateMetadata[_id].length == 0,
            "certificate already has metadata set"
        );

        certificateMetadata[_id] = _metadata;
        emit CertificateMetadataSet(_id, _metadata);
    }

    function whitelistIssuer(
        address _issuer,
        uint256 _topic
    ) external onlyOwner {
        require(
            issuers[_topic] == address(0),
            "Topic already has an issuer assigned"
        );

        issuers[_topic] = _issuer;
        emit IssuerWhitelisted(_issuer, _topic);
    }

    function blacklistIssuer(
        address _issuer,
        uint256 _topic
    ) external onlyOwner {
        require(issuers[_topic] != address(0), "Topic doesn't have an issuer");
        require(
            issuers[_topic] == _issuer,
            "Blacklisted issuer is not the topic issuer"
        );

        issuers[_topic] = address(0);
        emit IssuerBlacklisted(_issuer, _topic);
    }

    function _methodSymbol(
        TransactionType _type
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_type);
    }

    /// @notice Validate if the certificate is valid against an external `_verifier` contract.
    function _validate(
        address _verifier,
        bytes memory _validityData
    ) internal view {
        (bool success, bytes memory result) = _verifier.staticcall(
            _validityData
        );

        require(success && abi.decode(result, (bool)), "Certificate invalid");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // TODO: Fix possible bug where an attacker could send TransactionType.MINT as data and circumvent this check
            // Suggestion: Only do this check if the sender is not the BatchFactory
            if (!_isTransferType(data, TransactionType.MINT)) {
                require(
                    ids[i] != 0 && ids[i] <= _latestCertificateId,
                    "Not a valid certificate ID"
                );
                _validate(
                    certificateStorage[ids[i]].issuer,
                    certificateStorage[ids[i]].validityData
                );
                _enoughBalance(from, ids[i], amounts[i]);
            }
        }
    }

    function _isTransferType(
        bytes memory _data,
        TransactionType _type
    ) private pure returns (bool) {
        return keccak256(_data) == keccak256(_methodSymbol(_type));
    }

    function _enoughBalance(
        address _from,
        uint256 _id,
        uint256 _value
    ) internal view {
        require(
            ERC1155Upgradeable.balanceOf(_from, _id) >= _value,
            "Insufficient balance"
        );
    }

    function _isIssuer(uint256 _topic) internal view {
        require(issuers[_topic] == _msgSender(), "Not the issuer");
    }

    function _toDynamicArray(
        uint256 _item
    ) internal pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = _item;
    }

    /// @notice Needed for OpenZeppelin contract upgradeability.
    /// @dev Allow only to the owner of the contract.
    function _authorizeUpgrade(address) internal override onlyOwner {
        // Allow only owner to authorize a smart contract upgrade
    }
}
