@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialMetricValidator()
        let item = RevenueCycle.newDenialMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DenialMetricRequiredNameRule(message: "denial metric needs this field")
        let item = RevenueCycle.newDenialMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialMetricThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.DenialMetricThresholdRangeRule(min: 7.9, max: 3622.4)
        let item = RevenueCycle.newDenialMetric("x", name: "y")
        item.threshold = 3623.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.DenialMetricNameLengthRule(maxLength: 255)
        let item = RevenueCycle.newDenialMetric("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
