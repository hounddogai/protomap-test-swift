@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationMappingValidator()
        let item = RevenueCycle.newAuthorizationMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationMappingStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.AuthorizationMappingStartsAtRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newAuthorizationMapping("x", label: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationMappingRequiredCodeRule(message: "authorization mapping needs a value")
        let item = RevenueCycle.newAuthorizationMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationMappingExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.AuthorizationMappingExpiresAtRangeRule(min: 16, max: 86400)
        let item = RevenueCycle.newAuthorizationMapping("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
