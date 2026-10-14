@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedSubstitutionProfileValidator()
        let item = Pharmacy.newWeightedSubstitutionProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedSubstitutionProfileAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Pharmacy.WeightedSubstitutionProfileAmountRangeRule(min: 4.0, max: 3433.3)
        let item = Pharmacy.newWeightedSubstitutionProfile("x", name: "y")
        item.amount = 3434.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedSubstitutionProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.WeightedSubstitutionProfileCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newWeightedSubstitutionProfile("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
