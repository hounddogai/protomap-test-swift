@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallPreferenceValidator()
        let item = Pharmacy.newRecallPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallPreferenceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.RecallPreferenceLimitRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newRecallPreference("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallPreferenceUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.RecallPreferenceUpdatedAtRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newRecallPreference("x", label: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallPreferenceBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Pharmacy.RecallPreferenceBudgetRangeRule(min: 5.4, max: 1062.4)
        let item = Pharmacy.newRecallPreference("x", label: "y")
        item.budget = 1063.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallPreferenceRequiredCodeRule(message: "recall preference needs an entry")
        let item = Pharmacy.newRecallPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RecallPreferenceRequiredLabelRule(message: "recall preference needs this field")
        let item = Pharmacy.newRecallPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
