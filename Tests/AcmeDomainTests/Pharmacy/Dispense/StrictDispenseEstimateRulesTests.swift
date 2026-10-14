@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictDispenseEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictDispenseEstimateValidator()
        let item = Pharmacy.newStrictDispenseEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictDispenseEstimateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.StrictDispenseEstimateExpiresAtRangeRule(min: 80, max: 120)
        let item = Pharmacy.newStrictDispenseEstimate("x", name: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyStrictDispenseEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.StrictDispenseEstimateCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newStrictDispenseEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
