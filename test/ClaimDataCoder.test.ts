/* eslint-disable no-unused-expressions */
import { expect } from "chai";
import { ClaimDataCoder, IClaimData } from "../src";

export const CLAIM_DATA: IClaimData = {
  beneficiary: "c9fc-4a6c-efa4-43c7-af35-cf361d3b67ae",
  region: "region",
  countryCode: "HR",
  periodStartDate: "2021-01-01",
  periodEndDate: "2021-12-31",
  purpose: "Decarbonization",
  consumptionEntityID: "74b205b6-e4cf-46eb-99d8-9aeb922f83e7",
  proofID: "11a3b3dc-d74a-4b72-b6cb-01ef2d8e7e91",
  data: "",
};

describe("ClaimDataCoder", () => {
  it("Should be able to decode variable length metadata", async () => {
    const encodedData = ClaimDataCoder.encode(CLAIM_DATA);
    const decodedData = ClaimDataCoder.decode(encodedData);

    expect(decodedData).to.deep.equal(CLAIM_DATA);
  });
});
