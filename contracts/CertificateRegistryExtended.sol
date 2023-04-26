// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CertificateRegistry.sol";

/// @title Certificate Registry Extended
/// @author Josip Bagaric
/// @notice Credits: A part of this codebase was copied from by Energy Web Foundation's Origin implementation
contract CertificateRegistryExtended is CertificateRegistry {
    event TransferBatchMultiple(
        address indexed operator,
        address[] from,
        address[] to,
        uint256[] ids,
        uint256[] values
    );
    event ClaimBatchMultiple(
        address[] _claimIssuer,
        address[] _claimSubject,
        uint256[] indexed _topics,
        uint256[] _ids,
        uint256[] _values,
        bytes[] _claimData
    );

    function initialize(string memory _uri) public initializer {
        CertificateRegistry.__CertificateRegistry_init(_uri);
    }

    /// @notice Similar to {IERC1888-batchIssue}, but not a part of the ERC-1888 standard.
    /// @dev Allows batch issuing to an array of _to addresses.
    /// @dev `_to` cannot be the zero addresses.
    /// @dev `_to`, `_data`, `_values`, `_topics` and `_validityData` must have the same length.
    function batchIssueMultiple(
        address[] memory _to,
        bytes[] memory _validityData,
        uint256[] memory _topics,
        uint256[] memory _values,
        bytes[] memory _data
    ) external returns (uint256[] memory ids) {
        require(_values.length > 0, "no values specified");

        ids = new uint256[](_values.length);

        address operator = _msgSender();

        for (uint256 i = 0; i < _values.length; i++) {
            _isIssuer(_topics[i]);
            _validate(operator, _validityData[i]);
            ids[i] = i + _latestCertificateId + 1;
        }

        for (uint256 i = 0; i < ids.length; i++) {
            certificateStorage[ids[i]] = Certificate({
                topic: _topics[i],
                issuer: operator,
                validityData: _validityData[i],
                data: _data[i]
            });
        }

        _latestCertificateId = ids[ids.length - 1];

        // Moved to a separate loop to stop re-entrancy
        for (uint256 i = 0; i < ids.length; i++) {
            ERC1155Upgradeable._mint(
                _to[i],
                ids[i],
                _values[i],
                _methodSymbol(TransactionType.MINT)
            );
        }

        emit IssuanceBatch(operator, _topics, ids, _values);
    }

    /// @notice Similar to {ERC1155-safeBatchTransferFrom}, but not a part of the ERC-1155 standard.
    /// @dev Allows batch transferring to/from an array of addresses.
    function safeBatchTransferFromMultiple(
        address[] memory _from,
        address[] memory _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes[] memory _data
    ) external {
        require(_values.length > 0, "no values specified");

        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _from[i] == _msgSender() ||
                    ERC1155Upgradeable.isApprovedForAll(_from[i], _msgSender()),
                "not owner nor approved"
            );
            _beforeTokenTransfer(
                _msgSender(),
                _from[i],
                _to[i],
                _toDynamicArray(_ids[i]),
                _toDynamicArray(_values[i]),
                _data[i]
            );
        }

        address operator = _msgSender();

        for (uint256 i = 0; i < _ids.length; ++i) {
            _safeTransferFrom(
                _from[i],
                _to[i],
                _ids[i],
                _values[i],
                _methodSymbol(TransactionType.TRANSFER)
            );
        }

        emit TransferBatchMultiple(operator, _from, _to, _ids, _values);
    }

    /// @notice Similar to {IERC1888-safeBatchTransferAndClaimFrom}, but not a part of the ERC-1888 standard.
    /// @dev Allows batch claiming to/from an array of addresses.
    function safeBatchTransferAndClaimFromMultiple(
        address[] memory _from,
        address[] memory _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes[] memory _data,
        bytes[] memory _claimData
    ) external {
        require(_ids.length > 0, "no certificates specified");

        uint256[] memory topics = new uint256[](_ids.length);

        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _from[i] == _msgSender() ||
                    ERC1155Upgradeable.isApprovedForAll(_from[i], _msgSender()),
                "not owner nor approved"
            );
            _beforeTokenTransfer(
                _msgSender(),
                _from[i],
                _to[i],
                _toDynamicArray(_ids[i]),
                _toDynamicArray(_values[i]),
                _data[i]
            );
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            topics[i] = certificateStorage[_ids[i]].topic;
            claimedBalances[_ids[i]][_to[i]] += _values[i];
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            _burn(_from[i], _ids[i], _values[i]);
        }

        emit ClaimBatchMultiple(_from, _to, topics, _ids, _values, _claimData);
    }

    function version() external pure returns (string memory) {
        return "1.2.0";
    }
}
