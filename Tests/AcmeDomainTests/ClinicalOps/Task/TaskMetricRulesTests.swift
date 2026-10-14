@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskMetricValidator()
        let item = ClinicalOps.newTaskMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.TaskMetricTitleLengthRule(maxLength: 80)
        let item = ClinicalOps.newTaskMetric("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskMetricMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.TaskMetricMinimumRangeRule(min: 7.5, max: 1097.3)
        let item = ClinicalOps.newTaskMetric("x", title: "y")
        item.minimum = 1098.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.TaskMetricRequiredTitleRule(message: "task metric needs this field")
        let item = ClinicalOps.newTaskMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskMetricRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = ClinicalOps.TaskMetricRequiredLocaleRule(message: "task metric needs an entry")
        let item = ClinicalOps.newTaskMetric("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskMetricCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newTaskMetric("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
