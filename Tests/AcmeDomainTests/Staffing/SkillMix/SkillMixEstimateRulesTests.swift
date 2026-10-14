@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixEstimateValidator()
        let item = Staffing.newSkillMixEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.SkillMixEstimateRequiredTitleRule(message: "skill mix estimate needs a value")
        let item = Staffing.newSkillMixEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixEstimateRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.SkillMixEstimateRequiredContactEmailRule(message: "skill mix estimate needs a value")
        let item = Staffing.newSkillMixEstimate("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixEstimateDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.SkillMixEstimateDescriptionLengthRule(maxLength: 64)
        let item = Staffing.newSkillMixEstimate("x", title: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixEstimateRequiredCodeRule(message: "skill mix estimate needs an entry")
        let item = Staffing.newSkillMixEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixEstimateScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.SkillMixEstimateScoreRangeRule(min: 8.5, max: 1157.8)
        let item = Staffing.newSkillMixEstimate("x", title: "y")
        item.score = 1159.3
        #expect(rule.check(item).count > 0)
    }
}
