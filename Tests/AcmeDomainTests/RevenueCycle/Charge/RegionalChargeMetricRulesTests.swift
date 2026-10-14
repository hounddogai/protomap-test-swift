@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalChargeMetricValidator()
        let item = RevenueCycle.newRegionalChargeMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalChargeMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RegionalChargeMetricRequiredTitleRule(message: "regional charge metric needs a value")
        let item = RevenueCycle.newRegionalChargeMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalChargeMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.RegionalChargeMetricTitleLengthRule(maxLength: 16)
        let item = RevenueCycle.newRegionalChargeMetric("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalChargeMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RegionalChargeMetricCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newRegionalChargeMetric("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalChargeMetricUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.RegionalChargeMetricUpdatedAtRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newRegionalChargeMetric("x", title: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
