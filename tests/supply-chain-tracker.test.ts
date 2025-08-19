import { describe, it, expect, beforeEach } from "vitest";

interface Step {
  timestamp: bigint;
  actor: string;
  description: string;
  verified: boolean;
  data?: Uint8Array;
}

interface Item {
  owner: string;
  stepCount: bigint;
}

const mockContract = {
  admin: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM" as string,
  oracle: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM" as string,
  paused: false as boolean,
  items: new Map<bigint, Item>(),
  steps: new Map<string, Step>(), // Key as `${itemId}-${index}`
  MAX_STEPS_PER_ITEM: 50n,

  isAdmin(caller: string): boolean {
    return caller === this.admin;
  },

  isOracle(caller: string): boolean {
    return caller === this.oracle;
  },

  isItemOwner(caller: string, itemId: bigint): boolean {
    const item = this.items.get(itemId);
    return !!item && item.owner === caller;
  },

  setPaused(caller: string, pause: boolean): { value: boolean } | { error: number } {
    if (!this.isAdmin(caller)) return { error: 200 };
    this.paused = pause;
    return { value: pause };
  },

  setOracle(caller: string, newOracle: string): { value: boolean } | { error: number } {
    if (!this.isAdmin(caller)) return { error: 200 };
    this.oracle = newOracle;
    return { value: true };
  },

  initSupplyChain(caller: string, itemId: bigint, owner: string): { value: boolean } | { error: number } {
    if (this.paused) return { error: 204 };
    if (!this.isAdmin(caller) && caller !== owner) return { error: 200 };
    if (this.items.has(itemId)) return { error: 201 }; // Invert for init err, but example uses found for add
    this.items.set(itemId, { owner, stepCount: 0n });
    return { value: true };
  },

  addStep(caller: string, itemId: bigint, description: string, data?: Uint8Array): { value: bigint } | { error: number } {
    if (this.paused) return { error: 204 };
    if (!this.isItemOwner(caller, itemId)) return { error: 200 };
    if (description.length === 0) return { error: 206 };
    const item = this.items.get(itemId);
    if (!item) return { error: 201 };
    if (item.stepCount >= this.MAX_STEPS_PER_ITEM) return { error: 207 };
    const newIndex = item.stepCount;
    const key = `${itemId.toString()}-${newIndex.toString()}`;
    this.steps.set(key, { timestamp: 100n, actor: caller, description, verified: false, data });
    item.stepCount += 1n;
    return { value: newIndex };
  },

  verifyStep(caller: string, itemId: bigint, index: bigint): { value: boolean } | { error: number } {
    if (this.paused) return { error: 204 };
    if (!this.isOracle(caller)) return { error: 208 };
    const item = this.items.get(itemId);
    if (!item) return { error: 201 };
    if (index >= item.stepCount) return { error: 203 };
    const key = `${itemId.toString()}-${index.toString()}`;
    const step = this.steps.get(key);
    if (!step) return { error: 203 };
    if (step.verified) return { error: 202 };
    step.verified = true;
    return { value: true };
  },

  transferOwnership(caller: string, itemId: bigint, newOwner: string): { value: boolean } | { error: number } {
    if (this.paused) return { error: 204 };
    if (!this.isItemOwner(caller, itemId)) return { error: 200 };
    const item = this.items.get(itemId);
    if (!item) return { error: 201 };
    item.owner = newOwner;
    return { value: true };
  },

  getStepCount(itemId: bigint): { value: bigint } | { error: number } {
    const item = this.items.get(itemId);
    if (!item) return { error: 201 };
    return { value: item.stepCount };
  },

  getStep(itemId: bigint, index: bigint): { value: Step } | { error: number } {
    const item = this.items.get(itemId);
    if (!item || index >= item.stepCount) return { error: 203 };
    const key = `${itemId.toString()}-${index.toString()}`;
    const step = this.steps.get(key);
    if (!step) return { error: 203 };
    return { value: step };
  },
};

describe("EcoThread Supply Chain Tracker", () => {
  beforeEach(() => {
    mockContract.admin = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM";
    mockContract.oracle = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM";
    mockContract.paused = false;
    mockContract.items = new Map();
    mockContract.steps = new Map();
  });

  it("should initialize supply chain for a new item", () => {
    const result = mockContract.initSupplyChain(mockContract.admin, 1n, "ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    expect(result).toEqual({ value: true });
    expect(mockContract.items.get(1n)?.owner).toBe("ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    expect(mockContract.items.get(1n)?.stepCount).toBe(0n);
  });

  it("should add a step to an item", () => {
    mockContract.initSupplyChain(mockContract.admin, 1n, "ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    const result = mockContract.addStep("ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5", 1n, "Sourcing materials", undefined);
    expect(result).toEqual({ value: 0n });
    expect(mockContract.items.get(1n)?.stepCount).toBe(1n);
    const stepResult = mockContract.getStep(1n, 0n) as { value: Step };
    expect(stepResult.value.description).toBe("Sourcing materials");
    expect(stepResult.value.verified).toBe(false);
  });

  it("should verify a step as oracle", () => {
    mockContract.initSupplyChain(mockContract.admin, 1n, "ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    mockContract.addStep("ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5", 1n, "Sourcing materials", undefined);
    const result = mockContract.verifyStep(mockContract.oracle, 1n, 0n);
    expect(result).toEqual({ value: true });
    const stepResult = mockContract.getStep(1n, 0n) as { value: Step };
    expect(stepResult.value.verified).toBe(true);
  });

  it("should prevent verifying already verified step", () => {
    mockContract.initSupplyChain(mockContract.admin, 1n, "ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    mockContract.addStep("ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5", 1n, "Sourcing materials", undefined);
    mockContract.verifyStep(mockContract.oracle, 1n, 0n);
    const result = mockContract.verifyStep(mockContract.oracle, 1n, 0n);
    expect(result).toEqual({ error: 202 });
  });

  it("should transfer ownership", () => {
    mockContract.initSupplyChain(mockContract.admin, 1n, "ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    const result = mockContract.transferOwnership("ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5", 1n, "ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP");
    expect(result).toEqual({ value: true });
    expect(mockContract.items.get(1n)?.owner).toBe("ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP");
  });

  it("should not allow actions when paused", () => {
    mockContract.setPaused(mockContract.admin, true);
    const initResult = mockContract.initSupplyChain(mockContract.admin, 1n, "ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    expect(initResult).toEqual({ error: 204 });
  });

  it("should prevent adding step over max", () => {
    mockContract.initSupplyChain(mockContract.admin, 1n, "ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5");
    for (let i = 0; i < 50; i++) {
      mockContract.addStep("ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5", 1n, `Step ${i}`, undefined);
    }
    const result = mockContract.addStep("ST2CY5V39NHDP5PWEYNE3GT6RMOZYXLD0H6E2BWX5", 1n, "Extra step", undefined);
    expect(result).toEqual({ error: 207 });
  });
});