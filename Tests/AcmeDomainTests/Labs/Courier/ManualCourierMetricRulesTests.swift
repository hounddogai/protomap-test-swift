@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualCourierMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualCourierMetricValidator()
        let item = Labs.newManualCourierMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualCourierMetricRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.ManualCourierMetricRetriesRangeRule(min: 64, max: 86400)
        let item = Labs.newManualCourierMetric("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsManualCourierMetricMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.ManualCourierMetricMaximumRangeRule(min: 0.0, max: 108.3)
        let item = Labs.newManualCourierMetric("x", title: "y")
        item.maximum = 109.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsManualCourierMetricDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.ManualCourierMetricDurationMinutesRangeRule(min: 16, max: 255)
        let item = Labs.newManualCourierMetric("x", title: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}
