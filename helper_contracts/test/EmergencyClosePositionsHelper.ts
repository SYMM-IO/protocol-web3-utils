import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("EmergencyClosePositionsHelper", function () {
  let emergencyClosePositionsHelper: any;
  let mockSymmio: any;
  let mockPartyB: any;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy mock contracts
    const MockSymmio = await ethers.getContractFactory("MockSymmio");
    mockSymmio = await MockSymmio.deploy();

    const MockPartyB = await ethers.getContractFactory("MockPartyB");
    mockPartyB = await MockPartyB.deploy();

    // Deploy EmergencyClosePositionsHelper
    const EmergencyClosePositionsHelper = await ethers.getContractFactory(
      "EmergencyClosePositionsHelper"
    );
    emergencyClosePositionsHelper = await EmergencyClosePositionsHelper.deploy(
      await mockSymmio.getAddress(),
      await mockPartyB.getAddress(),
      await owner.getAddress()
    );
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await emergencyClosePositionsHelper.owner()).to.equal(
        await owner.getAddress()
      );
    });

    it("Should set the correct Symmio address", async function () {
      expect(await emergencyClosePositionsHelper.symmioAddress()).to.equal(
        await mockSymmio.getAddress()
      );
    });

    it("Should set the correct PartyB address", async function () {
      expect(await emergencyClosePositionsHelper.partyBAddress()).to.equal(
        await mockPartyB.getAddress()
      );
    });
  });

  describe("emergencyClosePositions", function () {
    it("Should revert if called by non-owner", async function () {
      await expect(
        emergencyClosePositionsHelper.connect(addr1).emergencyClosePositions([])
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if PartyB is already in emergency status", async function () {
      await mockSymmio.setPartyBEmergencyStatus(
        [await mockPartyB.getAddress()],
        true
      );
      await expect(
        emergencyClosePositionsHelper.emergencyClosePositions([])
      ).to.be.revertedWith(
        "EmergencyClosePositionsHelper: PartyB is already in emergency status"
      );
    });

    it("Should revert if callData is invalid", async function () {
      const invalidCallData = ethers.randomBytes(3); // Less than 4 bytes
      await expect(
        emergencyClosePositionsHelper.emergencyClosePositions([invalidCallData])
      ).to.be.revertedWith("EmergencyClosePositionsHelper: Invalid call data");
    });

    it("Should revert if function selector is not emergencyClosePosition", async function () {
      const invalidCallData = ethers.randomBytes(4);
      await expect(
        emergencyClosePositionsHelper.emergencyClosePositions([invalidCallData])
      ).to.be.revertedWith(
        "EmergencyClosePositionsHelper: Only emergencyClosePosition in allowed"
      );
    });

    it("Should successfully execute emergencyClosePositions", async function () {
      // Mock the emergencyClosePosition function selector
      const functionSelector = "0xa3039431";
      const mockCallData =
        functionSelector +
        "0000000000000000000000000000000000000000000000000000000000000001"; // Mocked parameters

      // Execute emergencyClosePositions
      await expect(
        emergencyClosePositionsHelper.emergencyClosePositions([mockCallData])
      )
        .to.emit(mockSymmio, "PartyBEmergencyStatusSet")
        .withArgs(await mockPartyB.getAddress(), true)
        .to.emit(mockPartyB, "CallExecuted")
        .to.emit(mockSymmio, "PartyBEmergencyStatusSet")
        .withArgs(await mockPartyB.getAddress(), false);

      // Verify that PartyB's emergency status was set back to false
      expect(
        await mockSymmio.getPartyBEmergencyStatus(await mockPartyB.getAddress())
      ).to.be.false;
    });
  });
});
