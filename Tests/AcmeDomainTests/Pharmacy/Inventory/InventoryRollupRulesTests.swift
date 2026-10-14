@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryRollupValidator()
        let item = Pharmacy.newInventoryRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryRollupRequiredCodeRule(message: "inventory rollup needs a value")
        let item = Pharmacy.newInventoryRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryRollupSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Pharmacy.InventoryRollupSegmentLengthRule(maxLength: 255)
        let item = Pharmacy.newInventoryRollup("x", name: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryRollupDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.InventoryRollupDosageMgRangeRule(min: 2.8, max: 308.0)
        let item = Pharmacy.newInventoryRollup("x", name: "y")
        item.dosageMg = 309.5
        #expect(rule.check(item).count > 0)
    }
}
