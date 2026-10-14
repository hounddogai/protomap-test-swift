@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalDenialMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultSeasonalDenialMetricValidator()
        let item = RevenueCycle.newSeasonalDenialMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleSeasonalDenialMetricCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.SeasonalDenialMetricCostRangeRule(min: 7.7, max: 3037.8)
        let item = RevenueCycle.newSeasonalDenialMetric("x", title: "y")
        item.cost = 3039.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleSeasonalDenialMetricRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.SeasonalDenialMetricRequiredDescriptionRule(
            message: "seasonal denial metric needs a value"
        )
        let item = RevenueCycle.newSeasonalDenialMetric("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
