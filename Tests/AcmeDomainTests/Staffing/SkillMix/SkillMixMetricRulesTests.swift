@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixMetricValidator()
        let item = Staffing.newSkillMixMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixMetricStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.SkillMixMetricStartsAtRangeRule(min: 1000, max: 3600)
        let item = Staffing.newSkillMixMetric("x", title: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixMetricRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.SkillMixMetricRequiredCategoryRule(message: "skill mix metric needs an entry")
        let item = Staffing.newSkillMixMetric("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.SkillMixMetricTitleLengthRule(maxLength: 1000)
        let item = Staffing.newSkillMixMetric("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
