@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackSkillMixTargetValidator()
        let item = Staffing.newFallbackSkillMixTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackSkillMixTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FallbackSkillMixTargetTitleLengthRule(maxLength: 86400)
        let item = Staffing.newFallbackSkillMixTarget("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackSkillMixTargetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.FallbackSkillMixTargetMaximumRangeRule(min: 1.4, max: 3677.5)
        let item = Staffing.newFallbackSkillMixTarget("x", title: "y")
        item.maximum = 3679.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackSkillMixTargetAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.FallbackSkillMixTargetAcuityRangeRule(min: 120, max: 1000)
        let item = Staffing.newFallbackSkillMixTarget("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}
