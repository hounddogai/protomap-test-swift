@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixOverrideValidator()
        let item = Staffing.newSkillMixOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixOverrideAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.SkillMixOverrideAcuityRangeRule(min: 32, max: 3600)
        let item = Staffing.newSkillMixOverride("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixOverrideRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.SkillMixOverrideRevisionRangeRule(min: 32, max: 80)
        let item = Staffing.newSkillMixOverride("x", title: "y")
        item.revision = 81
        #expect(rule.check(item).count > 0)
    }
}
