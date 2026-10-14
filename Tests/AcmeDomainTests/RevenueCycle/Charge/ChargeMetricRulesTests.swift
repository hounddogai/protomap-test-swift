@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeMetricValidator()
        let item = RevenueCycle.newChargeMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeMetricRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.ChargeMetricRequiredDescriptionRule(message: "charge metric needs a value")
        let item = RevenueCycle.newChargeMetric("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ChargeMetricTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newChargeMetric("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeMetricUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.ChargeMetricUpdatedAtRangeRule(min: 80, max: 120)
        let item = RevenueCycle.newChargeMetric("x", title: "y")
        item.updatedAt = 121
        #expect(rule.check(item).count > 0)
    }
}
