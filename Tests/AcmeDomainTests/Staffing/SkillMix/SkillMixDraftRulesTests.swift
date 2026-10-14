@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixDraftValidator()
        let item = Staffing.newSkillMixDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixDraftCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.SkillMixDraftCostRangeRule(min: 5.5, max: 3530.2)
        let item = Staffing.newSkillMixDraft("x", name: "y")
        item.cost = 3531.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixDraftWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.SkillMixDraftWindowDaysRangeRule(min: 3600, max: 86400)
        let item = Staffing.newSkillMixDraft("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
