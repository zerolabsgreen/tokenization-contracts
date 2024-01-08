import { AbiCoder } from "ethers";

export interface IClaimData {
  beneficiary: string;
  region: string;
  countryCode: string;
  periodStartDate: string;
  periodEndDate: string;
  purpose: string;
  consumptionEntityID: string;
  proofID: string;
  data: string;
}

export class ClaimDataCoder {
  static encode(metadata: IClaimData): string {
    return AbiCoder.defaultAbiCoder().encode(Array(9).fill("string"), [
      metadata.beneficiary,
      metadata.region,
      metadata.countryCode,
      metadata.periodStartDate,
      metadata.periodEndDate,
      metadata.purpose,
      metadata.consumptionEntityID,
      metadata.proofID,
      metadata.data,
    ]);
  }

  static decode(encodedMetadata: string): IClaimData {
    const [
      beneficiary,
      region,
      countryCode,
      periodStartDate,
      periodEndDate,
      purpose,
      consumptionEntityID,
      proofID,
      data,
    ] = AbiCoder.defaultAbiCoder().decode(
      Array(9).fill("string"),
      encodedMetadata
    );

    return {
      beneficiary,
      region,
      countryCode,
      periodStartDate,
      periodEndDate,
      purpose,
      consumptionEntityID,
      proofID,
      data,
    };
  }
}
