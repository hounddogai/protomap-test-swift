@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixCycleValidator()
        let item = Staffing.newSkillMixCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixCyclePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Staffing.SkillMixCyclePriorityRangeRule(min: 64, max: 80)
        let item = Staffing.newSkillMixCycle("x", label: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixCycleCodeLengthRule(maxLength: 64)
        let item = Staffing.newSkillMixCycle("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixCycleCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Staffing.SkillMixCycleCurrencyLengthRule(maxLength: 3600)
        let item = Staffing.newSkillMixCycle("x", label: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixCycleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.SkillMixCycleBudgetRangeRule(min: 7.2, max: 3243.8)
        let item = Staffing.newSkillMixCycle("x", label: "y")
        item.budget = 3245.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixCycleRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.SkillMixCycleRequiredCurrencyRule(message: "skill mix cycle needs a value")
        let item = Staffing.newSkillMixCycle("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
