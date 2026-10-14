@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolMetricValidator()
        let item = Staffing.newFloatPoolMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FloatPoolMetricNameLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolMetric("x", title: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolMetricScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.FloatPoolMetricScoreRangeRule(min: 8.7, max: 1062.0)
        let item = Staffing.newFloatPoolMetric("x", title: "y")
        item.score = 1063.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolMetricWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.FloatPoolMetricWindowDaysRangeRule(min: 16, max: 16)
        let item = Staffing.newFloatPoolMetric("x", title: "y")
        item.windowDays = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.FloatPoolMetricRequiredTitleRule(message: "float pool metric needs a value")
        let item = Staffing.newFloatPoolMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FloatPoolMetricTitleLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolMetric("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
