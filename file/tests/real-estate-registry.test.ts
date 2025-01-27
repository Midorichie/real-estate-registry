import { describe, test, expect, beforeEach } from 'vitest';
import { deployContract, callContract, readOnlyCall } from '@hirosystems/clarinet-sdk'; // Use the correct SDK for interacting with Clarity contracts.

describe("Real Estate Registry Contract Tests", () => {
  const wallet1 = 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5';
  const wallet2 = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  const wallet3 = 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC';

  const validPropertyId = 'P12345';
  const validPropertyDetails = '123 Main St, City, State, 12345';
  const invalidPropertyId = '12345'; // ID doesn't meet expected format
  const invalidPropertyDetails = 'Invalid';

  beforeEach(async () => {
    await deployContract(
      'real-estate-registry',
      './contracts/real-estate-registry.clar' // Path to the contract file
    );
  });

  test("Should fail with invalid property ID", async () => {
    const result = await callContract(
      'real-estate-registry',
      'register-property',
      [invalidPropertyId, validPropertyDetails],
      wallet1
    );
    expect(result.success).toBe(false); // Expect failure for invalid property ID.
  });

  test("Should fail with invalid property details", async () => {
    const result = await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, invalidPropertyDetails],
      wallet1
    );
    expect(result.success).toBe(false); // Expect failure for invalid property details.
  });

  test("Should successfully register a property", async () => {
    const result = await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    expect(result.success).toBe(true);
  });

  test("Should not allow duplicate property registration", async () => {
    await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    const duplicateResult = await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    expect(duplicateResult.success).toBe(false);
  });

  test("Should allow property listing for sale", async () => {
    await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    const result = await callContract(
      'real-estate-registry',
      'list-property-for-sale',
      [validPropertyId, 1000000],
      wallet1
    );
    expect(result.success).toBe(true);
  });

  test("Should not allow unauthorized listing", async () => {
    await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    const unauthorizedResult = await callContract(
      'real-estate-registry',
      'list-property-for-sale',
      [validPropertyId, 1000000],
      wallet2
    );
    expect(unauthorizedResult.success).toBe(false);
  });

  test("Should allow property purchase", async () => {
    await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    await callContract(
      'real-estate-registry',
      'list-property-for-sale',
      [validPropertyId, 1000000],
      wallet1
    );
    const purchaseResult = await callContract(
      'real-estate-registry',
      'buy-property',
      [validPropertyId],
      wallet2
    );
    expect(purchaseResult.success).toBe(true);
  });

  test("Should fail when buying unlisted property", async () => {
    await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    const result = await callContract(
      'real-estate-registry',
      'buy-property',
      [validPropertyId],
      wallet2
    );
    expect(result.success).toBe(false);
  });

  test("Should return correct owner property count", async () => {
    await callContract(
      'real-estate-registry',
      'register-property',
      [validPropertyId, validPropertyDetails],
      wallet1
    );
    const secondPropertyId = validPropertyId + "2";
    await callContract(
      'real-estate-registry',
      'register-property',
      [secondPropertyId, validPropertyDetails],
      wallet1
    );
    const countResult = await readOnlyCall(
      'real-estate-registry',
      'get-owner-property-count',
      [wallet1]
    );
    expect(countResult.result).toBe(2); // Owner should have two properties.
  });
});
