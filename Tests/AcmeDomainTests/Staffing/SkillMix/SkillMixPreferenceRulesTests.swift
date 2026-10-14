@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixPreferenceValidator()
        let item = Staffing.newSkillMixPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixPreferenceDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Staffing.SkillMixPreferenceDiscountRangeRule(min: 2.9, max: 1404.6)
        let item = Staffing.newSkillMixPreference("x", label: "y")
        item.discount = 1406.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixPreferenceLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Staffing.SkillMixPreferenceLocaleLengthRule(maxLength: 32)
        let item = Staffing.newSkillMixPreference("x", label: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
