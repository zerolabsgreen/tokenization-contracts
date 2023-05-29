import { utils } from 'ethers';
import { cleanStringUnicodeChars, extractProductType } from './utils';

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
    const decodedMetadata = cleanStringUnicodeChars(utils.toUtf8String(encodedMetadata));
    const [productType, energySources, countryRegion, agreementId, orderId] = decodedMetadata.replace('---', '--').split('--');
    const [country, region] = countryRegion.split('-');
    
    return {
      productType: extractProductType(productType),
      energySources: energySources.split(/\||,/),
      country,
      region,
      agreementId,
      orderId
    };
  }
}
