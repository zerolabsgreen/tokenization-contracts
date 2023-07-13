import { decodeDynamicArray, encodeDynamicArray } from './utils';

export interface IClaimData {
  beneficiary: string;
  region: string;
  countryCode: string;
  periodStartDate: string;
  periodEndDate: string;
  purpose: string;
  consumptionEntityID: string;
  proofID: string;
  data?: string;
}

export class ClaimDataCoder {
  static encode(claimData: IClaimData): string {  
    return encodeDynamicArray([
      claimData.beneficiary,
      claimData.region,
      claimData.countryCode,
      claimData.periodStartDate,
      claimData.periodEndDate,
      claimData.purpose,
      claimData.consumptionEntityID,
      claimData.proofID,
      claimData.data ?? ''
    ]);
  }

  static decode(encodedClaimData: string): IClaimData {
    const [
      beneficiary,
      region,
      countryCode,
      periodStartDate,
      periodEndDate,
      purpose,
      consumptionEntityID,
      proofID,
      data
    ] = decodeDynamicArray(encodedClaimData);

    return {
      beneficiary,
      region,
      countryCode,
      periodStartDate,
      periodEndDate,
      purpose,
      consumptionEntityID,
      proofID,
      data
    };
  }
}
