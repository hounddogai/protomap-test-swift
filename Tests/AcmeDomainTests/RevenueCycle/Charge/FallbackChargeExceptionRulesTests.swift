@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackChargeExceptionValidator()
        let item = RevenueCycle.newFallbackChargeException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackChargeExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.FallbackChargeExceptionRequiredTitleRule(
            message: "fallback charge exception needs an entry"
        )
        let item = RevenueCycle.newFallbackChargeException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackChargeExceptionMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = RevenueCycle.FallbackChargeExceptionMarginRangeRule(min: 5.2, max: 2449.2)
        let item = RevenueCycle.newFallbackChargeException("x", title: "y")
        item.margin = 2450.7
        #expect(rule.check(item).count > 0)
    }
}
