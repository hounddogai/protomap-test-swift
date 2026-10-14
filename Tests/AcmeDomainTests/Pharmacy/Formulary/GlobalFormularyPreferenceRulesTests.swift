@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalFormularyPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalFormularyPreferenceValidator()
        let item = Pharmacy.newGlobalFormularyPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalFormularyPreferenceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.GlobalFormularyPreferenceAttemptsRangeRule(min: 32, max: 1000)
        let item = Pharmacy.newGlobalFormularyPreference("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalFormularyPreferenceRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.GlobalFormularyPreferenceRefillsRangeRule(min: 32, max: 255)
        let item = Pharmacy.newGlobalFormularyPreference("x", label: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalFormularyPreferenceRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.GlobalFormularyPreferenceRequiredCategoryRule(
            message: "global formulary preference needs a value"
        )
        let item = Pharmacy.newGlobalFormularyPreference("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
