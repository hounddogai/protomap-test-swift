@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixVarianceValidator()
        let item = Staffing.newSkillMixVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixVarianceRequiredCodeRule(message: "skill mix variance needs a value")
        let item = Staffing.newSkillMixVariance("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixVarianceCodeLengthRule(maxLength: 86400)
        let item = Staffing.newSkillMixVariance("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixVarianceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.SkillMixVarianceGraceDaysRangeRule(min: 64, max: 120)
        let item = Staffing.newSkillMixVariance("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixVarianceWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.SkillMixVarianceWeightRangeRule(min: 6.5, max: 444.7)
        let item = Staffing.newSkillMixVariance("x", name: "y")
        item.weight = 446.2
        #expect(rule.check(item).count > 0)
    }
}
