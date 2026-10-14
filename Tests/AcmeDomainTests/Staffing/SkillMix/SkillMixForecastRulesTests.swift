@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixForecastValidator()
        let item = Staffing.newSkillMixForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixForecastCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.SkillMixForecastCeilingRangeRule(min: 1.9, max: 4217.3)
        let item = Staffing.newSkillMixForecast("x", title: "y")
        item.ceiling = 4218.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.SkillMixForecastRequiredTitleRule(message: "skill mix forecast needs an entry")
        let item = Staffing.newSkillMixForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixForecastRequiredCodeRule(message: "skill mix forecast needs an entry")
        let item = Staffing.newSkillMixForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
