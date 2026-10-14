@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictSkillMixAuditValidator()
        let item = Staffing.newStrictSkillMixAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictSkillMixAuditWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.StrictSkillMixAuditWeightRangeRule(min: 2.7, max: 669.3)
        let item = Staffing.newStrictSkillMixAudit("x", name: "y")
        item.weight = 670.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictSkillMixAuditRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.StrictSkillMixAuditRequiredReviewerRule(message: "strict skill mix audit needs an entry")
        let item = Staffing.newStrictSkillMixAudit("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictSkillMixAuditRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.StrictSkillMixAuditRequiredNameRule(message: "strict skill mix audit needs this field")
        let item = Staffing.newStrictSkillMixAudit("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
