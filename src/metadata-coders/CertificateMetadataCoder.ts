import { BigNumber, utils } from 'ethers';

export interface IGenerator {
  id: string;
  name: string;
  energySource: string;
  region: string;
  country: string;
  capacity: BigNumber;
  commissioningDate: number;
}

export interface ICertificateMetadata {
  generator: IGenerator;
  generationStartTime: number;
  generationEndTime: number;
  productType: string;
  data: string;
}

export const generatorParamType = utils.ParamType.from({
  type: 'array',
  name: 'generator',
  components: [
    { type: 'string', name: "id" },
    { type: 'string', name: "name" },
    { type: 'string', name: "energySource" },
    { type: 'string', name: "region" },
    { type: 'string', name: "country" },
    { type: 'uint256', name: "commissioningDate" },
    { type: 'uint256', name: "capacity" },
  ]
});

export class CertificateMetadataCoder {
  static encode(metadata: ICertificateMetadata): string {
    return utils.defaultAbiCoder.encode(
      [
        generatorParamType,
        "uint256",
        "uint256",
        "string",
        "string",
      ],
      [
        {
          id: metadata.generator.id ?? '',
          name: metadata.generator.name ?? '',
          energySource: metadata.generator.energySource  ?? '',
          region: metadata.generator.region ?? '',
          country: metadata.generator.country ?? '',
          commissioningDate: metadata.generator.commissioningDate  ?? 0,
          capacity: metadata.generator.capacity ?? 0,
        },
        metadata.generationStartTime ?? 0,
        metadata.generationEndTime ?? 0,
        metadata.productType ?? '',
        metadata.data ?? '',
      ]
    );
  }

  static decode(encodedMetadata: string): ICertificateMetadata {
    const [
      generator,
      generationStartTime,
      generationEndTime,
      productType,
      data,
    ] = utils.defaultAbiCoder.decode(
      [
        generatorParamType,
        "uint256",
        "uint256",
        "string",
        "string"
      ],
      encodedMetadata
    );
  
    return {
      generator: {
        id: generator.id,
        energySource: generator.energySource,
        region: generator.region,
        country: generator.country,
        name: generator.name,
        commissioningDate: generator.commissioningDate.toNumber(),
        capacity: generator.capacity
      },
      generationStartTime: generationStartTime.toNumber(),
      generationEndTime: generationEndTime.toNumber(),
      productType,
      data,
    };
  }
}
