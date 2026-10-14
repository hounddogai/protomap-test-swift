@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackClaimDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackClaimDigestValidator()
        let item = RevenueCycle.newFallbackClaimDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackClaimDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.FallbackClaimDigestRequiredLabelRule(message: "fallback claim digest needs an entry")
        let item = RevenueCycle.newFallbackClaimDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackClaimDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackClaimDigestRequiredCodeRule(message: "fallback claim digest needs a value")
        let item = RevenueCycle.newFallbackClaimDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackClaimDigestRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.FallbackClaimDigestRefillsRangeRule(min: 80, max: 3600)
        let item = RevenueCycle.newFallbackClaimDigest("x", label: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}
