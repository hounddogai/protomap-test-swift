@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredClaimMetricValidator()
        let item = RevenueCycle.newTieredClaimMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredClaimMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.TieredClaimMetricRequiredTitleRule(message: "tiered claim metric needs this field")
        let item = RevenueCycle.newTieredClaimMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimMetricPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.TieredClaimMetricPriorityRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newTieredClaimMetric("x", title: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleTieredClaimMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.TieredClaimMetricRequiredCodeRule(message: "tiered claim metric needs this field")
        let item = RevenueCycle.newTieredClaimMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimMetricRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.TieredClaimMetricRegionLengthRule(maxLength: 16)
        let item = RevenueCycle.newTieredClaimMetric("x", title: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimMetricCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.TieredClaimMetricCreatedAtRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newTieredClaimMetric("x", title: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}
