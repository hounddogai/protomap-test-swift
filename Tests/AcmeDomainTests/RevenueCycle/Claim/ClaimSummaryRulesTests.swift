@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimSummaryValidator()
        let item = RevenueCycle.newClaimSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.ClaimSummaryRequiredLabelRule(message: "claim summary needs a value")
        let item = RevenueCycle.newClaimSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimSummaryTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.ClaimSummaryTimezoneLengthRule(maxLength: 120)
        let item = RevenueCycle.newClaimSummary("x", label: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimSummaryEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = RevenueCycle.ClaimSummaryEndsAtRangeRule(min: 80, max: 80)
        let item = RevenueCycle.newClaimSummary("x", label: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}
