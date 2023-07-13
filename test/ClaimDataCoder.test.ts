/* eslint-disable no-unused-expressions */
import { expect } from "chai";
import { randomUUID } from "crypto";
import { ClaimDataCoder, IClaimData } from "../src";

export const CLAIM_DATA: IClaimData = {
  beneficiary: "Test beneficiary",
  region: "string",
  countryCode: "string",
  periodStartDate: "string",
  periodEndDate: "string",
  purpose: "Some long string that will be longer than 32 bytes so that we can test 64 bytes and higher",
  consumptionEntityID: "string",
  proofID: "string",
};

describe("ClaimDataCoder", () => {
  it("Should be able to decode variable length metadata", async () => {
      const encodedData = ClaimDataCoder.encode(CLAIM_DATA);
      const decodedData = ClaimDataCoder.decode(encodedData);

      expect(decodedData).to.deep.equal({
        ...CLAIM_DATA,
        data: ''
      });
  });
});
