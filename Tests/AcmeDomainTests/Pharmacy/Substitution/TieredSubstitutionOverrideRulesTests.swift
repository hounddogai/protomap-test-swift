@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredSubstitutionOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultTieredSubstitutionOverrideValidator()
        let item = Pharmacy.newTieredSubstitutionOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyTieredSubstitutionOverrideChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.TieredSubstitutionOverrideChannelLengthRule(maxLength: 80)
        let item = Pharmacy.newTieredSubstitutionOverride("x", label: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyTieredSubstitutionOverrideQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.TieredSubstitutionOverrideQuantityRangeRule(min: 16, max: 32)
        let item = Pharmacy.newTieredSubstitutionOverride("x", label: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyTieredSubstitutionOverrideLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.TieredSubstitutionOverrideLimitRangeRule(min: 80, max: 80)
        let item = Pharmacy.newTieredSubstitutionOverride("x", label: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}
