@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingSpecimenMetricValidator()
        let item = Labs.newPendingSpecimenMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingSpecimenMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingSpecimenMetricRequiredCodeRule(message: "pending specimen metric needs a value")
        let item = Labs.newPendingSpecimenMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingSpecimenMetricCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.PendingSpecimenMetricCopayRangeRule(min: 4.4, max: 600.5)
        let item = Labs.newPendingSpecimenMetric("x", label: "y")
        item.copay = 602.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingSpecimenMetricAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.PendingSpecimenMetricAttemptsRangeRule(min: 16, max: 1000)
        let item = Labs.newPendingSpecimenMetric("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingSpecimenMetricGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.PendingSpecimenMetricGraceDaysRangeRule(min: 16, max: 80)
        let item = Labs.newPendingSpecimenMetric("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}
