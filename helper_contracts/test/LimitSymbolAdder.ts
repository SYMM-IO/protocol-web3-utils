import { expect } from "chai"
import { ethers } from "hardhat"
import { LimitedSymbolAdder, MockSymmio } from "../typechain-types"
import { Signer } from "ethers"

describe("LimitedSymbolAdder", function () {
	let limitedSymbolAdder: LimitedSymbolAdder
	let mockSymmio: MockSymmio
	let admin: Signer, setter: Signer, operator: Signer, pauser: Signer, otherAccount: Signer
	let dailyLimit: number

	const getDefaultSymbols = () => [
		{
			symbolId: 1,
			name: "BLAST",
			isValid: true,
			minAcceptableQuoteValue: ethers.parseEther("100"),
			minAcceptablePortionLF: ethers.parseEther("0.1"),
			tradingFee: ethers.parseEther("0.01"),
			maxLeverage: ethers.parseEther("10"),
			fundingRateEpochDuration: 86400,
			fundingRateWindowTime: 3600,
		},
		{
			symbolId: 2,
			name: "BNB",
			isValid: true,
			minAcceptableQuoteValue: ethers.parseEther("200"),
			minAcceptablePortionLF: ethers.parseEther("0.05"),
			tradingFee: ethers.parseEther("0.015"),
			maxLeverage: ethers.parseEther("15"),
			fundingRateEpochDuration: 86400,
			fundingRateWindowTime: 3600,
		},
	]

	const getExtraSymbols = () => [
		{
			symbolId: 3,
			name: "ARBITRUM",
			isValid: true,
			minAcceptableQuoteValue: ethers.parseEther("150"),
			minAcceptablePortionLF: ethers.parseEther("0.08"),
			tradingFee: ethers.parseEther("0.012"),
			maxLeverage: ethers.parseEther("12"),
			fundingRateEpochDuration: 86400,
			fundingRateWindowTime: 3600,
		},
		{
			symbolId: 4,
			name: "BASE",
			isValid: true,
			minAcceptableQuoteValue: ethers.parseEther("300"),
			minAcceptablePortionLF: ethers.parseEther("0.04"),
			tradingFee: ethers.parseEther("0.02"),
			maxLeverage: ethers.parseEther("20"),
			fundingRateEpochDuration: 86400,
			fundingRateWindowTime: 3600,
		},
		{
			symbolId: 5,
			name: "MANTLE",
			isValid: true,
			minAcceptableQuoteValue: ethers.parseEther("400"),
			minAcceptablePortionLF: ethers.parseEther("0.02"),
			tradingFee: ethers.parseEther("0.03"),
			maxLeverage: ethers.parseEther("30"),
			fundingRateEpochDuration: 86400,
			fundingRateWindowTime: 3600,
		},
		{
			symbolId: 6,
			name: "EXTRA_SYMBOL",
			isValid: true,
			minAcceptableQuoteValue: ethers.parseEther("500"),
			minAcceptablePortionLF: ethers.parseEther("0.01"),
			tradingFee: ethers.parseEther("0.05"),
			maxLeverage: ethers.parseEther("50"),
			fundingRateEpochDuration: 86400,
			fundingRateWindowTime: 3600,
		},
	]

	beforeEach(async function () {
		const LimitedSymbolAdder = await ethers.getContractFactory("LimitedSymbolAdder")
		const MockSymmio = await ethers.getContractFactory("MockSymmio")

		mockSymmio = await MockSymmio.deploy()
		;[admin, setter, operator, pauser, otherAccount] = await ethers.getSigners()

		dailyLimit = 5
		limitedSymbolAdder = await LimitedSymbolAdder.deploy(
			await mockSymmio.getAddress(),
			await admin.getAddress(),
			await setter.getAddress(),
			await operator.getAddress(),
			dailyLimit,
		)

		// Set up symbols in MockSymmio
		const defaultSymbols = getDefaultSymbols()
		const extraSymbols = getExtraSymbols()
		const allSymbols = [...defaultSymbols, ...extraSymbols]
		for (const symbol of allSymbols) {
			await mockSymmio.setMockSymbol(symbol.symbolId, symbol)
		}
	})

	it("Should add symbols if within the daily limit", async function () {
		const symbols = getDefaultSymbols()

		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols)).to.not.be.reverted
	})

	it("Should revert if exceeding the daily limit", async function () {
		const symbols = [...getDefaultSymbols(), ...getExtraSymbols()]

		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols)).to.be.revertedWithCustomError(limitedSymbolAdder, "DailyLimitExceeded")
	})

	it("Should revert if an empty list of symbols is provided", async function () {
		const symbols: any[] = []

		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols)).to.be.revertedWithCustomError(limitedSymbolAdder, "InvalidSymbolsList")
	})

	it("Should reset the symbols count after a day passes", async function () {
		const symbols = getDefaultSymbols()

		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols)).to.not.be.reverted

		await ethers.provider.send("evm_increaseTime", [24 * 60 * 60])
		await ethers.provider.send("evm_mine", [])

		const extraSymbols = getExtraSymbols()
		await expect(limitedSymbolAdder.connect(operator).addSymbols(extraSymbols.slice(0, 5))).to.not.be.reverted
	})

	it("Should allow setter to update the daily limit", async function () {
		const newLimit = 10
		await limitedSymbolAdder.connect(setter).setDailyLimit(newLimit)
		expect(await limitedSymbolAdder.dailyLimit()).to.equal(newLimit)
	})

	it("Should not allow non-setter to update the daily limit", async function () {
		const newLimit = 10
		await expect(limitedSymbolAdder.connect(otherAccount).setDailyLimit(newLimit)).to.be.revertedWith(/AccessControl: account .* is missing role .*/)
	})

	it("Should allow admin to pause and unpause the contract", async function () {
		await limitedSymbolAdder.connect(admin).pause()
		await expect(limitedSymbolAdder.connect(operator).addSymbols([getDefaultSymbols()[0]])).to.be.revertedWith("Pausable: paused")

		await limitedSymbolAdder.connect(admin).unpause()
		await expect(limitedSymbolAdder.connect(operator).addSymbols([getDefaultSymbols()[0]])).to.not.be.reverted
	})

	it("Should revert if attempting to add a duplicate symbol", async function () {
		const symbols = getDefaultSymbols()

		// Add symbols once
		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols)).to.not.be.reverted

		// Attempt to add the same symbols again, expecting a revert
		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols))
			.to.be.revertedWithCustomError(limitedSymbolAdder, "DuplicateSymbol")
			.withArgs(symbols[0].name)
	})

	it("Should load symbols from Symmio and store their hashes", async function () {
		const start = 0
		const size = 5 // Total symbols we set up in MockSymmio

		await expect(limitedSymbolAdder.connect(setter).loadSymmioSymbols(start, size))
			.to.emit(limitedSymbolAdder, "SymmioSymbolsLoaded")
			.withArgs(start, size)

		// Attempt to add the same symbols via addSymbols(), should revert with DuplicateSymbol
		const symbolsToTest = [...getDefaultSymbols(), ...getExtraSymbols().slice(0, 3)] // total of 5 symbols

		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbolsToTest))
			.to.be.revertedWithCustomError(limitedSymbolAdder, "DuplicateSymbol")
			.withArgs(symbolsToTest[0].name)
	})

	it("Should not allow non-setter to call loadSymmioSymbols", async function () {
		await expect(limitedSymbolAdder.connect(otherAccount).loadSymmioSymbols(0, 2)).to.be.revertedWith(/AccessControl: account .* is missing role .*/)
	})

	it("Should clear the stored symbol hashes", async function () {
		// First, the setter loads symbols from Symmio
		const start = 0
		const size = 2
		await limitedSymbolAdder.connect(setter).loadSymmioSymbols(start, size)

		// Now the symbol hashes are stored, adding the same symbols should revert
		const symbols = getDefaultSymbols()
		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols))
			.to.be.revertedWithCustomError(limitedSymbolAdder, "DuplicateSymbol")
			.withArgs(symbols[0].name)

		// Now, the setter clears the symbol hashes
		await expect(limitedSymbolAdder.connect(setter).clearSymbolHashes())
			.to.emit(limitedSymbolAdder, "SymbolHashesCleared")
			.withArgs(await setter.getAddress())

		// Now, adding the symbols should succeed
		await expect(limitedSymbolAdder.connect(operator).addSymbols(symbols)).to.not.be.reverted
	})

	it("Should not allow non-setter to call clearSymbolHashes", async function () {
		await expect(limitedSymbolAdder.connect(otherAccount).clearSymbolHashes()).to.be.revertedWith(/AccessControl: account .* is missing role .*/)
	})
})
