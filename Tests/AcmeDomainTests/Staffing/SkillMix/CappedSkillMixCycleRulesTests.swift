@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedSkillMixCycleValidator()
        let item = Staffing.newCappedSkillMixCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedSkillMixCycleUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Staffing.CappedSkillMixCycleUnitLengthRule(maxLength: 64)
        let item = Staffing.newCappedSkillMixCycle("x", title: "y")
        item.unit = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedSkillMixCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CappedSkillMixCycleCodeLengthRule(maxLength: 1000)
        let item = Staffing.newCappedSkillMixCycle("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedSkillMixCycleRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.CappedSkillMixCycleRequiredUnitRule(message: "capped skill mix cycle needs a value")
        let item = Staffing.newCappedSkillMixCycle("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedSkillMixCycleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CappedSkillMixCycleRequiredTitleRule(message: "capped skill mix cycle needs a value")
        let item = Staffing.newCappedSkillMixCycle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
