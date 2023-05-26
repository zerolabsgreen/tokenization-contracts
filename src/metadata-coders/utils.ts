import { BigNumber, utils } from "ethers";

export const decodeDynamicArray = (encodedString: string): string[] => {
  if (encodedString.length < 2) {
    throw new Error(`Needs to be at least 2 characters long`);
  }

  if (encodedString.substring(0, 2) != '0x') {
    throw new Error(`Needs to be at 0x prefixed`);
  }

  encodedString = encodedString.substring(2);

  const itemsLength = BigNumber.from('0x' + encodedString.substring(0, 64)).toNumber();
  
  encodedString = encodedString.substring(64);

  let currentIndex = 0;
  let offsets: number[] = []

  for (let i = 0; i < itemsLength; i++) {
    const nextIndex = currentIndex + 64;

    const offsetHex = '0x' + encodedString.substring(currentIndex, nextIndex);
    const offset = BigNumber.from(offsetHex);

    offsets.push(offset.toNumber());
    currentIndex = nextIndex;
  }

  offsets = offsets.map(offset => offset - Math.min(...offsets) + 32);

  encodedString = encodedString.substring(itemsLength * 64);

  let decodedStrings: string[] = [];

  for (let i = 1; i <= offsets.length; i++) {
    const isLast = i == offsets.length;

    const previousOffset = offsets[i - 1];
    const lengthInBytes = offsets[i] - previousOffset;

    const hexString = isLast
      ? encodedString.substring(previousOffset * 2)
      : encodedString.substring(previousOffset * 2, (previousOffset + lengthInBytes) * 2);

    decodedStrings.push(cleanStringUnicodeChars(utils.toUtf8String('0x' + hexString)));
  }

  return decodedStrings;
};

export const encodeDynamicArray = (data: string[]): string => {
  let offsets: number[] = [];
  let encodedStrings: string[] = [];

  const itemsLength = utils.hexZeroPad(utils.hexlify(BigNumber.from(data.length)), 32).substring(2);

  for (const str of data) {
    const utf8EncodedString = utils.hexlify(utils.toUtf8Bytes(str));

    let len = 32;

    while (true) {
      try {
        const paddedString = utils.hexZeroPad(utf8EncodedString, len);
        encodedStrings.push(paddedString);
        offsets.push((offsets.length > 0 ? Math.max(...offsets) : 0) + len);

        break;
      } catch (e) {
        len += 32;
      }
    }
  }

  const paddedOffsets = offsets.map(
    offset => utils.hexZeroPad(
      utils.hexlify(BigNumber.from(offset)), 32
    ).substring(2)).join('')

  const paddedData = encodedStrings.map(data => data.substring(2)).join('');

  return '0x'
    + itemsLength
    + paddedOffsets
    + utils.hexZeroPad(utils.hexlify(BigNumber.from(0)), 32).substring(2)
    + paddedData;
};

export const cleanStringUnicodeChars = (str: string): string => str.replace(/[\x00-\x1F\x7F]/g, '');