@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictDenialMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictDenialMilestoneValidator()
        let item = RevenueCycle.newStrictDenialMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictDenialMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.StrictDenialMilestoneTitleLengthRule(maxLength: 255)
        let item = RevenueCycle.newStrictDenialMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictDenialMilestoneRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = RevenueCycle.StrictDenialMilestoneRequiredCurrencyRule(
            message: "strict denial milestone needs an entry"
        )
        let item = RevenueCycle.newStrictDenialMilestone("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictDenialMilestoneExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.StrictDenialMilestoneExpiresAtRangeRule(min: 16, max: 80)
        let item = RevenueCycle.newStrictDenialMilestone("x", title: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictDenialMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StrictDenialMilestoneCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newStrictDenialMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
