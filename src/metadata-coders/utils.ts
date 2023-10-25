import { ProductType } from "./types";

// Export a function to clean a string from undesired Unicode characters.
export const cleanStringUnicodeChars = (input: string): string =>
  input.replace(/[\x00-\x1F\x7F]/g, "");

// Export a function to extract a product type from a given input string.
export const extractProductType = (input: string): string => {
  // Retrieve all product type values.
  const productTypeValues = Object.values(ProductType);
  // Find a matching product type in the input string.
  const matchingProductType = productTypeValues.find((value) =>
    input.includes(value)
  );

  // Return the matching product type or an empty string if not found.
  return matchingProductType ?? "";
};
