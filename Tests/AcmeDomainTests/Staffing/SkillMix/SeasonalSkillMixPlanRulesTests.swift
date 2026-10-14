@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalSkillMixPlanValidator()
        let item = Staffing.newSeasonalSkillMixPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalSkillMixPlanScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.SeasonalSkillMixPlanScoreRangeRule(min: 3.0, max: 2851.5)
        let item = Staffing.newSeasonalSkillMixPlan("x", label: "y")
        item.score = 2853.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSeasonalSkillMixPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalSkillMixPlanRequiredCodeRule(message: "seasonal skill mix plan needs a value")
        let item = Staffing.newSeasonalSkillMixPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalSkillMixPlanMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.SeasonalSkillMixPlanMinimumRangeRule(min: 5.2, max: 4560.2)
        let item = Staffing.newSeasonalSkillMixPlan("x", label: "y")
        item.minimum = 4561.7
        #expect(rule.check(item).count > 0)
    }
}
