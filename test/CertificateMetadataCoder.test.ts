/* eslint-disable no-unused-expressions */
import { expect } from "chai";
import { BigNumber } from "ethers";
import { CertificateMetadataCoder, ICertificateMetadata } from "../src";
import { DateTime } from "luxon";

export const TEST_METADATA: ICertificateMetadata = {
  generator: {
    id: "123",
    name: "Ime",
    energySource: "SOLAR",
    region: "EU",
    country: "HR",
    capacity: BigNumber.from(1e9),
    commissioningDate: DateTime.fromISO("2017-05-15").valueOf(),
  },
  generationStartTime: DateTime.fromISO("2022-01-01").valueOf(),
  generationEndTime: DateTime.fromISO("2022-01-31").valueOf(),
  productType: "I-REC",
  data: 'test_external_id',
};

describe("CertificateMetadataCoder", () => {
  describe("Minting metadata encoding", async () => {
    it("Should properly encode metadata", async () => {
      const encodedMetadata = CertificateMetadataCoder.encode(TEST_METADATA);
      const decodedMetadata = CertificateMetadataCoder.decode(encodedMetadata);

      expect(TEST_METADATA.data).to.equal(decodedMetadata.data);
      expect(TEST_METADATA.productType).to.equal(decodedMetadata.productType);
      expect(TEST_METADATA.generationEndTime).to.equal(decodedMetadata.generationEndTime);
      expect(TEST_METADATA.generationStartTime).to.equal(decodedMetadata.generationStartTime);
      expect(TEST_METADATA.generator.commissioningDate).to.equal(decodedMetadata.generator.commissioningDate);
      expect(TEST_METADATA.generator.capacity.toNumber()).to.equal(decodedMetadata.generator.capacity.toNumber());
      expect(TEST_METADATA.generator.id).to.equal(decodedMetadata.generator.id);
      expect(TEST_METADATA.generator.name).to.equal(decodedMetadata.generator.name);
      expect(TEST_METADATA.generator.energySource).to.equal(decodedMetadata.generator.energySource);
      expect(TEST_METADATA.generator.region).to.equal(decodedMetadata.generator.region);
      expect(TEST_METADATA.generator.country).to.equal(decodedMetadata.generator.country);
    });
    it("Should work with partially empty metadata", async () => {
      const encodedMetadata = CertificateMetadataCoder.encode({ ...TEST_METADATA, generator: {
        ...TEST_METADATA.generator,
        id: undefined as unknown as string,
        name: undefined as unknown as string,
        commissioningDate: undefined as unknown as number,
        capacity: undefined as unknown as BigNumber
      } });
      const decodedMetadata = CertificateMetadataCoder.decode(encodedMetadata);

      expect(decodedMetadata.data).to.equal(TEST_METADATA.data);
      expect(decodedMetadata.productType).to.equal(TEST_METADATA.productType);
      expect(decodedMetadata.generationEndTime).to.equal(TEST_METADATA.generationEndTime);
      expect(decodedMetadata.generationStartTime).to.equal(TEST_METADATA.generationStartTime);
      expect(decodedMetadata.generator.commissioningDate).to.equal(0);
      expect(decodedMetadata.generator.capacity.toNumber()).to.equal(0);
      expect(decodedMetadata.generator.id).to.equal('');
      expect(decodedMetadata.generator.name).to.equal('');
      expect(decodedMetadata.generator.energySource).to.equal(TEST_METADATA.generator.energySource);
      expect(decodedMetadata.generator.region).to.equal(TEST_METADATA.generator.region);
      expect(decodedMetadata.generator.country).to.equal(TEST_METADATA.generator.country);
    });

    it("Should work with all empty metadata", async () => {
      const encodedMetadata = CertificateMetadataCoder.encode({
        generator: {
          id: undefined as unknown as string,
          name: undefined as unknown as string,
          energySource: undefined as unknown as string,
          region: undefined as unknown as string,
          country: undefined as unknown as string,
          capacity: undefined as unknown as BigNumber,
          commissioningDate: undefined as unknown as number,
        },
        generationStartTime: undefined as unknown as number,
        generationEndTime: undefined as unknown as number,
        productType: undefined as unknown as string,
        data: undefined as unknown as string,
      });
      const decodedMetadata = CertificateMetadataCoder.decode(encodedMetadata);

      expect(decodedMetadata.data).to.equal('');
      expect(decodedMetadata.productType).to.equal('');
      expect(decodedMetadata.generationEndTime).to.equal(0);
      expect(decodedMetadata.generationStartTime).to.equal(0);
      expect(decodedMetadata.generator.commissioningDate).to.equal(0);
      expect(decodedMetadata.generator.capacity.toNumber()).to.equal(0);
      expect(decodedMetadata.generator.id).to.equal('');
      expect(decodedMetadata.generator.name).to.equal('');
      expect(decodedMetadata.generator.energySource).to.equal('');
      expect(decodedMetadata.generator.region).to.equal('');
      expect(decodedMetadata.generator.country).to.equal('');
    });
  });
});
