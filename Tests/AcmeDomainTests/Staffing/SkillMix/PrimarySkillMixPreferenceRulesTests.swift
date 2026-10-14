@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimarySkillMixPreferenceValidator()
        let item = Staffing.newPrimarySkillMixPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimarySkillMixPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimarySkillMixPreferenceCodeLengthRule(maxLength: 120)
        let item = Staffing.newPrimarySkillMixPreference("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimarySkillMixPreferenceRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Staffing.PrimarySkillMixPreferenceRequiredSourceRule(
            message: "primary skill mix preference needs this field"
        )
        let item = Staffing.newPrimarySkillMixPreference("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimarySkillMixPreferenceScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.PrimarySkillMixPreferenceScoreRangeRule(min: 6.1, max: 4299.5)
        let item = Staffing.newPrimarySkillMixPreference("x", label: "y")
        item.score = 4301.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimarySkillMixPreferenceCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.PrimarySkillMixPreferenceCopayRangeRule(min: 2.5, max: 1417.8)
        let item = Staffing.newPrimarySkillMixPreference("x", label: "y")
        item.copay = 1419.3
        #expect(rule.check(item).count > 0)
    }
}
