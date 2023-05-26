import { utils } from 'ethers';

export interface IAgreementMetadata {
  productType: string;
  energySources: string[];
  country: string;
  region: string;
  agreementId: string;
  orderId: string;
}

export class AgreementMetadataCoder {
  static encode(metadata: IAgreementMetadata): string {
    const metadataConcatenatedString = [
      metadata.productType,
      metadata.energySources.join(','),
      [metadata.country, metadata.region].join('-'),
      metadata.agreementId,
      metadata.orderId
    ].join('--');

    const bytes = utils.toUtf8Bytes(metadataConcatenatedString);
    return utils.hexlify(bytes);
  }

  static decode(encodedMetadata: string): IAgreementMetadata {
    const decodedMetadata = utils.toUtf8String(encodedMetadata).replace(/\x00/g, '');
    const [productType, energySources, countryRegion, agreementId, orderId] = decodedMetadata.replace('---', '--').split('--');
    const [country, region] = countryRegion.split('-');
    
    return {
      productType,
      energySources: energySources.split(/\||,/),
      country,
      region,
      agreementId,
      orderId
    };
  }
}
