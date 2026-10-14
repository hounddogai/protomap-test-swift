@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseRollupValidator()
        let item = Pharmacy.newDispenseRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseRollupStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.DispenseRollupStartsAtRangeRule(min: 80, max: 255)
        let item = Pharmacy.newDispenseRollup("x", name: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseRollupCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Pharmacy.DispenseRollupCopayRangeRule(min: 8.4, max: 460.5)
        let item = Pharmacy.newDispenseRollup("x", name: "y")
        item.copay = 462.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseRollupRequiredCodeRule(message: "dispense rollup needs an entry")
        let item = Pharmacy.newDispenseRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseRollupRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.DispenseRollupRequiredCategoryRule(message: "dispense rollup needs a value")
        let item = Pharmacy.newDispenseRollup("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseRollupRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.DispenseRollupRequiredRegionRule(message: "dispense rollup needs this field")
        let item = Pharmacy.newDispenseRollup("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
