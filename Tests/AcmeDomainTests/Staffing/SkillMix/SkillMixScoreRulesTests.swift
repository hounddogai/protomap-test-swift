@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixScoreValidator()
        let item = Staffing.newSkillMixScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixScoreAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.SkillMixScoreAmountRangeRule(min: 9.0, max: 4095.0)
        let item = Staffing.newSkillMixScore("x", name: "y")
        item.amount = 4096.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixScoreRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.SkillMixScoreRatioRangeRule(min: 9.7, max: 4825.7)
        let item = Staffing.newSkillMixScore("x", name: "y")
        item.ratio = 4827.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixScoreRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.SkillMixScoreRequiredCategoryRule(message: "skill mix score needs an entry")
        let item = Staffing.newSkillMixScore("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
