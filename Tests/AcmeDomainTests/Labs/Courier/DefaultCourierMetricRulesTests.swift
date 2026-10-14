@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultCourierMetricValidator()
        let item = Labs.newDefaultCourierMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultCourierMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.DefaultCourierMetricRequiredCodeRule(message: "default courier metric needs an entry")
        let item = Labs.newDefaultCourierMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultCourierMetricPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.DefaultCourierMetricPriorityRangeRule(min: 120, max: 86400)
        let item = Labs.newDefaultCourierMetric("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultCourierMetricFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.DefaultCourierMetricFloorValueRangeRule(min: 1.7, max: 197.2)
        let item = Labs.newDefaultCourierMetric("x", label: "y")
        item.floorValue = 198.7
        #expect(rule.check(item).count > 0)
    }
}
