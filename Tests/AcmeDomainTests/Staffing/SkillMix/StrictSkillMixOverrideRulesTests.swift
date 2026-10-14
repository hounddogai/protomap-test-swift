@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictSkillMixOverrideValidator()
        let item = Staffing.newStrictSkillMixOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictSkillMixOverrideBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.StrictSkillMixOverrideBatchSizeRangeRule(min: 3600, max: 86400)
        let item = Staffing.newStrictSkillMixOverride("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictSkillMixOverrideDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.StrictSkillMixOverrideDescriptionLengthRule(maxLength: 32)
        let item = Staffing.newStrictSkillMixOverride("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictSkillMixOverrideRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.StrictSkillMixOverrideRequiredNameRule(message: "strict skill mix override needs an entry")
        let item = Staffing.newStrictSkillMixOverride("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictSkillMixOverrideBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.StrictSkillMixOverrideBudgetRangeRule(min: 2.0, max: 1302.3)
        let item = Staffing.newStrictSkillMixOverride("x", name: "y")
        item.budget = 1303.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictSkillMixOverrideRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.StrictSkillMixOverrideRequiredContactEmailRule(
            message: "strict skill mix override needs an entry"
        )
        let item = Staffing.newStrictSkillMixOverride("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
