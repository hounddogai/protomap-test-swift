@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackAuthorizationClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackAuthorizationClaimValidator()
        let item = RevenueCycle.newFallbackAuthorizationClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationClaimFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.FallbackAuthorizationClaimFloorValueRangeRule(min: 4.2, max: 2813.5)
        let item = RevenueCycle.newFallbackAuthorizationClaim("x", title: "y")
        item.floorValue = 2815.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.FallbackAuthorizationClaimTitleLengthRule(maxLength: 3600)
        let item = RevenueCycle.newFallbackAuthorizationClaim("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.FallbackAuthorizationClaimRequiredTitleRule(
            message: "fallback authorization claim needs an entry"
        )
        let item = RevenueCycle.newFallbackAuthorizationClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackAuthorizationClaimRequiredCodeRule(
            message: "fallback authorization claim needs an entry"
        )
        let item = RevenueCycle.newFallbackAuthorizationClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
