// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./IAgreementFactory.sol";
import "./ERC1888/IERC1888.sol";
import "./AgreementProxyFactory.sol";

using ECDSAUpgradeable for bytes32;

contract AgreementFactory is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IAgreementFactory
{
    address[] private _agreements;
    address private _cloneImplementation;

    // Agreement address => Agreement data
    mapping(address => AgreementData) public agreementData;
    mapping(address => uint256) public agreementFilled; // UNUSED, left here for upgradeability
    mapping(address => bool) public agreementDeployed;

    mapping(address => uint256[]) public agreementFilledBy;
    mapping(address => mapping(uint256 => uint256))
        public agreementFilledByAmount;

    address public _registry;
    AgreementProxyFactory public _agreementProxyFactory;

    function initialize(address _registryAddress) public initializer {
        OwnableUpgradeable.__Ownable_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();

        setRegistry(_registryAddress);
    }

    function setRegistry(address _registryAddress) public onlyOwner {
        require(_registry == address(0), "Registry already set");
        require(
            _registryAddress != address(0),
            "Cannot set address 0x0 as registry"
        );
        _registry = _registryAddress;
    }

    function setProxyFactory(
        address _agreementProxyFactoryAddress
    ) public onlyOwner {
        require(
            address(_agreementProxyFactory) == address(0),
            "Proxy factory already set"
        );
        require(
            _agreementProxyFactoryAddress != address(0),
            "Cannot set address 0x0 as proxy factory"
        );
        _agreementProxyFactory = AgreementProxyFactory(
            _agreementProxyFactoryAddress
        );
    }

    function deployAgreements(
        uint256 _amount,
        bytes32[] memory salts
    ) public onlyOwner {
        require(_amount > 0, "_amount should be > 0");

        address[] memory deployedProxies = new address[](_amount);

        for (uint256 i = 0; i < _amount; i++) {
            address proxy = _agreementProxyFactory.createProxy(
                salts[i],
                abi.encodeWithSignature(
                    "setAgreementFactory(address)",
                    address(this)
                )
            );

            deployedProxies[i] = proxy;

            _agreements.push(proxy);
            agreementDeployed[proxy] = true;
        }

        emit AgreementsDeployed(deployedProxies);
    }

    function signAgreements(
        address[] memory _addresses,
        bytes[] memory _sellerSigs,
        bytes[] memory _buyerSigs,
        uint256[] memory _amounts,
        bytes[] memory _metadata
    ) public onlyOwner {
        require(_addresses.length > 0, "unable to sign 0 agreements");

        for (uint256 i = 0; i < _addresses.length; i++) {
            signAgreement(
                _addresses[i],
                _sellerSigs[i],
                _buyerSigs[i],
                _amounts[i],
                _metadata[i]
            );
        }
    }

    function signAgreementsUnilateral(
        address[] memory _addresses,
        bytes[] memory _sellerSigs,
        address[] memory _buyerAddresses,
        uint256[] memory _amounts,
        bytes[] memory _metadata
    ) public onlyOwner {
        require(_addresses.length > 0, "unable to sign 0 agreements");

        for (uint256 i = 0; i < _addresses.length; i++) {
            signAgreementUnilateral(
                _addresses[i],
                _sellerSigs[i],
                _buyerAddresses[i],
                _amounts[i],
                _metadata[i]
            );
        }
    }

    function getAgreement(
        address _agreement
    ) public view agreementExists(_agreement) returns (AgreementData memory) {
        return agreementData[_agreement];
    }

    function getAgreements(
        uint256 cursor,
        uint256 howMany
    ) public view returns (address[] memory values, uint256 newCursor) {
        uint256 length = howMany;

        if (length > _agreements.length - cursor) {
            length = _agreements.length - cursor;
        }

        values = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = _agreements[cursor + i];
        }

        return (values, cursor + length);
    }

    function predictAgreementAddresses(
        bytes32[] memory salts
    ) public view returns (address[] memory agreements) {
        return _agreementProxyFactory.predictAddresses(salts);
    }

    function signAgreement(
        address _agreement,
        bytes memory _sellerSig,
        bytes memory _buyerSig,
        uint256 _amount,
        bytes memory _metadata
    ) public onlyOwner agreementExists(_agreement) {
        bytes32 messageToSign = keccak256(abi.encodePacked(_agreement))
            .toEthSignedMessageHash();

        _signAgreement(
            _agreement,
            messageToSign.recover(_sellerSig),
            messageToSign.recover(_buyerSig),
            _amount,
            _metadata
        );
    }

    function signAgreementUnilateral(
        address _agreement,
        bytes memory _sellerSig,
        address _buyer,
        uint256 _amount,
        bytes memory _metadata
    ) public onlyOwner agreementExists(_agreement) {
        bytes32 messageToSign = keccak256(abi.encodePacked(_agreement))
            .toEthSignedMessageHash();

        _signAgreement(
            _agreement,
            messageToSign.recover(_sellerSig),
            _buyer,
            _amount,
            _metadata
        );
    }

    function getFilledAmount(
        address _agreement
    ) public view returns (uint256 filled) {
        filled = 0;

        for (uint256 i = 0; i < agreementFilledBy[_agreement].length; i++) {
            uint256 certificateId = agreementFilledBy[_agreement][i];
            filled += agreementFilledByAmount[_agreement][certificateId];
        }
    }

    function fulfilled(
        address _agreement
    ) public view agreementSigned(_agreement) returns (bool) {
        return getFilledAmount(_agreement) >= agreementData[_agreement].amount;
    }

    function claimAgreement(
        address _agreement,
        bytes calldata _data,
        bytes calldata _claimData
    ) public onlyOwner agreementSigned(_agreement) agreementValid(_agreement) {
        require(
            agreementFilledBy[_agreement].length > 0,
            "agreement hasn't been filled yet"
        );

        bool shouldClaim = false;

        for (uint256 i = 0; i < agreementFilledBy[_agreement].length; i++) {
            uint256 certificateId = agreementFilledBy[_agreement][i];
            uint256 unclaimedBalance = IERC1888(_registry).balanceOf(
                _agreement,
                certificateId
            );

            if (unclaimedBalance > 0) {
                shouldClaim = true;
            }
        }

        require(shouldClaim, "no unclaimed balance in this agreement");

        for (uint256 i = 0; i < agreementFilledBy[_agreement].length; i++) {
            uint256 certificateId = agreementFilledBy[_agreement][i];
            uint256 unclaimedBalance = IERC1888(_registry).balanceOf(
                _agreement,
                certificateId
            );

            if (unclaimedBalance > 0) {
                Agreement(_agreement).claim(
                    _registry,
                    agreementData[_agreement].buyer,
                    certificateId,
                    unclaimedBalance,
                    _data,
                    _claimData
                );
            }
        }

        emit AgreementClaimed(_agreement, _claimData);
    }

    function fillAgreement(
        uint256 _amount,
        uint256 _certificateId
    ) public agreementValid(_msgSender()) agreementSigned(_msgSender()) {
        address agreement = _msgSender();
        bool filledByCertificateBefore = false;

        for (uint256 i = 0; i < agreementFilledBy[agreement].length; i++) {
            if (agreementFilledBy[agreement][i] == _certificateId) {
                filledByCertificateBefore = true;
            }
        }

        if (!filledByCertificateBefore) {
            agreementFilledBy[agreement].push(_certificateId);
        }

        agreementFilledByAmount[agreement][_certificateId] += _amount;

        emit AgreementFilled(agreement, _certificateId, _amount);
    }

    function updateAmount(
        address _agreement,
        uint256 _newAmount,
        bytes memory _sellerSig,
        bytes memory _buyerSig
    ) public onlyOwner agreementSigned(_agreement) agreementValid(_agreement) {
        bytes32 messageHash = keccak256(
            abi.encode(AgreementChange.AMOUNT, _agreement, _newAmount)
        ).toEthSignedMessageHash();

        _signatureCheck(_agreement, messageHash, _sellerSig, _buyerSig);

        emit AgreementAmountUpdated(
            _agreement,
            agreementData[_agreement].amount,
            _newAmount
        );

        agreementData[_agreement].amount = _newAmount;
    }

    function updateMetadata(
        address _agreement,
        bytes memory _newMetadata,
        bytes memory _sellerSig,
        bytes memory _buyerSig
    ) public onlyOwner agreementSigned(_agreement) agreementValid(_agreement) {
        bytes32 messageHash = keccak256(
            abi.encode(AgreementChange.METADATA, _agreement, _newMetadata)
        ).toEthSignedMessageHash();

        _signatureCheck(_agreement, messageHash, _sellerSig, _buyerSig);

        emit AgreementMetadataUpdated(
            _agreement,
            agreementData[_agreement].metadata,
            _newMetadata
        );

        agreementData[_agreement].metadata = _newMetadata;
    }

    function invalidateAgreement(
        address _agreement,
        bytes memory _sellerSig,
        bytes memory _buyerSig
    ) public onlyOwner agreementSigned(_agreement) agreementValid(_agreement) {
        bytes32 messageHash = keccak256(
            abi.encode(AgreementChange.INVALIDATION, _agreement)
        ).toEthSignedMessageHash();
        _signatureCheck(_agreement, messageHash, _sellerSig, _buyerSig);

        agreementData[_agreement].valid = false;

        emit AgreementInvalidated(_agreement);
    }

    function _signAgreement(
        address _agreement,
        address _seller,
        address _buyer,
        uint256 _amount,
        bytes memory _metadata
    ) internal {
        require(_amount > 0, "amount should be higher than 0");
        require(
            agreementData[_agreement].buyer == address(0),
            "agreement already signed"
        );
        require(_seller != address(0), "seller cannot be zero");
        require(_buyer != address(0), "buyer cannot be zero");

        AgreementData memory data = AgreementData({
            buyer: _buyer,
            seller: _seller,
            amount: _amount,
            metadata: _metadata,
            valid: true
        });

        agreementData[_agreement] = data;

        emit AgreementSigned(_agreement, data.buyer, data.seller, data.amount);
    }

    function _signatureCheck(
        address _agreement,
        bytes32 _messageHash,
        bytes memory _sellerSig,
        bytes memory _buyerSig
    ) internal view agreementSigned(_agreement) {
        require(
            _messageHash.recover(_sellerSig) ==
                agreementData[_agreement].seller,
            "seller signature invalid"
        );
        require(
            _messageHash.recover(_buyerSig) == agreementData[_agreement].buyer,
            "buyer signature invalid"
        );
    }

    /// @notice Needed for OpenZeppelin contract upgradeability.
    /// @dev Allow only to the owner of the contract.
    function _authorizeUpgrade(address) internal override onlyOwner {
        // Allow only owner to authorize a smart contract upgrade
    }

    modifier agreementExists(address _agreement) {
        require(agreementDeployed[_agreement], "agreement doesn't exist");
        _;
    }

    modifier agreementValid(address _agreement) {
        require(agreementData[_agreement].valid, "invalid agreement");
        _;
    }

    modifier agreementSigned(address _agreement) {
        require(agreementDeployed[_agreement], "agreement doesn't exist");
        require(
            agreementData[_agreement].buyer != address(0),
            "agreement hasn't been signed"
        );
        _;
    }

    function owner()
        public
        view
        override(IAgreementFactory, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    function version() external pure returns (string memory) {
        return "1.2.2";
    }
}
