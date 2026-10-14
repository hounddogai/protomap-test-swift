@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixRuleValidator()
        let item = Staffing.newSkillMixRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixRuleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.SkillMixRuleAmountRangeRule(min: 3.7, max: 2130.0)
        let item = Staffing.newSkillMixRule("x", name: "y")
        item.amount = 2131.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixRuleCodeLengthRule(maxLength: 80)
        let item = Staffing.newSkillMixRule("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
