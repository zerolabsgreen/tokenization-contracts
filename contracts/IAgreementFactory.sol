// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IAgreementFactory {
    struct AgreementData {
        address buyer;
        address seller;
        uint256 amount;
        bytes metadata;
        bool valid;
    }

    enum AgreementChange {
        INVALIDATION,
        AMOUNT,
        METADATA
    }

    event AgreementsDeployed(address[] agreements);
    event AgreementSigned(
        address indexed agreementAddress,
        address indexed buyer,
        address indexed seller,
        uint256 amount
    );
    event AgreementFilled(
        address indexed agreementAddress,
        uint256 indexed certificateId,
        uint256 amount
    );
    event AgreementClaimed(address indexed agreementAddress, bytes claimData);

    event AgreementInvalidated(address indexed agreementAddress);
    event AgreementAmountUpdated(
        address indexed agreementAddress,
        uint256 oldAmount,
        uint256 newAmount
    );
    event AgreementMetadataUpdated(
        address indexed agreementAddress,
        bytes oldMetadata,
        bytes newMetadata
    );

    function getAgreement(
        address _agreement
    ) external view returns (AgreementData memory);

    function fillAgreement(uint256 _amount, uint256 _certificateId) external;

    function owner() external view returns (address);
}
