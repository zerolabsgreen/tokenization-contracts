/* eslint-disable no-unused-expressions */
import { expect } from "chai";
import { randomUUID } from "crypto";
import { AgreementMetadataCoder } from "../src";

describe("AgreementMetadataCoder", () => {
  it("Should be able to decode variable length metadata", async () => {
    for (let length = 1; length <= 10; length++) {
      const agreementMetadata = {
        productType: "REC",
        energySources: ["WIND", "SOLAR"],
        country: "US",
        region: "NY",
        agreementId: randomUUID(),
        orderId: randomUUID(),
        data: "test_data",
      };

      const encodedData = AgreementMetadataCoder.encode(agreementMetadata);
      const decodedData = AgreementMetadataCoder.decode(encodedData);

      expect(decodedData).to.deep.equal(agreementMetadata);
    }
  });
});
