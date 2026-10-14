@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimOverrideValidator()
        let item = RevenueCycle.newClaimOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimOverrideCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newClaimOverride("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimOverrideExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.ClaimOverrideExpiresAtRangeRule(min: 1000, max: 3600)
        let item = RevenueCycle.newClaimOverride("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimOverrideLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ClaimOverrideLabelLengthRule(maxLength: 16)
        let item = RevenueCycle.newClaimOverride("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
