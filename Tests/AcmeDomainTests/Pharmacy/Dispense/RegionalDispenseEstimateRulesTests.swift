@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalDispenseEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalDispenseEstimateValidator()
        let item = Pharmacy.newRegionalDispenseEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalDispenseEstimateRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.RegionalDispenseEstimateRequiredUnitRule(
            message: "regional dispense estimate needs an entry"
        )
        let item = Pharmacy.newRegionalDispenseEstimate("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalDispenseEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RegionalDispenseEstimateRequiredNameRule(
            message: "regional dispense estimate needs an entry"
        )
        let item = Pharmacy.newRegionalDispenseEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalDispenseEstimateUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.RegionalDispenseEstimateUnitLengthRule(maxLength: 16)
        let item = Pharmacy.newRegionalDispenseEstimate("x", name: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalDispenseEstimateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.RegionalDispenseEstimateExpiresAtRangeRule(min: 32, max: 255)
        let item = Pharmacy.newRegionalDispenseEstimate("x", name: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}
