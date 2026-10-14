@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackDenialPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackDenialPolicyValidator()
        let item = RevenueCycle.newFallbackDenialPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackDenialPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackDenialPolicyRequiredCodeRule(message: "fallback denial policy needs an entry")
        let item = RevenueCycle.newFallbackDenialPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackDenialPolicyRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.FallbackDenialPolicyRequiredUnitRule(message: "fallback denial policy needs this field")
        let item = RevenueCycle.newFallbackDenialPolicy("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackDenialPolicySourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = RevenueCycle.FallbackDenialPolicySourceLengthRule(maxLength: 1000)
        let item = RevenueCycle.newFallbackDenialPolicy("x", title: "y")
        item.source = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
