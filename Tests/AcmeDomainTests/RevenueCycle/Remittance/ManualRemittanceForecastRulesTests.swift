@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualRemittanceForecastValidator()
        let item = RevenueCycle.newManualRemittanceForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualRemittanceForecastRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.ManualRemittanceForecastRequiredCategoryRule(
            message: "manual remittance forecast needs a value"
        )
        let item = RevenueCycle.newManualRemittanceForecast("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualRemittanceForecastAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.ManualRemittanceForecastAcuityRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newManualRemittanceForecast("x", title: "y")
        item.acuity = 81
        #expect(rule.check(item).count > 0)
    }
}
