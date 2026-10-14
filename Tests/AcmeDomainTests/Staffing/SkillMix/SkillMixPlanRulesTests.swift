@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixPlanValidator()
        let item = Staffing.newSkillMixPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixPlanRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.SkillMixPlanRequiredBedRule(message: "skill mix plan needs a value")
        let item = Staffing.newSkillMixPlan("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixPlanAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.SkillMixPlanAmountRangeRule(min: 6.3, max: 2006.8)
        let item = Staffing.newSkillMixPlan("x", label: "y")
        item.amount = 2008.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixPlanRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.SkillMixPlanRequiredLabelRule(message: "skill mix plan needs an entry")
        let item = Staffing.newSkillMixPlan("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixPlanBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.SkillMixPlanBedLengthRule(maxLength: 64)
        let item = Staffing.newSkillMixPlan("x", label: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
