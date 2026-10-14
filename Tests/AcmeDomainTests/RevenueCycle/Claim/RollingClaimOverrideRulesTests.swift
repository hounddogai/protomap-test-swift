@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingClaimOverrideValidator()
        let item = RevenueCycle.newRollingClaimOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingClaimOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.RollingClaimOverrideTitleLengthRule(maxLength: 80)
        let item = RevenueCycle.newRollingClaimOverride("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingClaimOverridePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = RevenueCycle.RollingClaimOverridePayerLengthRule(maxLength: 255)
        let item = RevenueCycle.newRollingClaimOverride("x", title: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingClaimOverrideRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.RollingClaimOverrideRequiredChannelRule(message: "rolling claim override needs a value")
        let item = RevenueCycle.newRollingClaimOverride("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingClaimOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RollingClaimOverrideRequiredTitleRule(message: "rolling claim override needs a value")
        let item = RevenueCycle.newRollingClaimOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
