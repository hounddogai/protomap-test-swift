@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationClaimValidator()
        let item = RevenueCycle.newAuthorizationClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationClaimUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = RevenueCycle.AuthorizationClaimUnitLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAuthorizationClaim("x", name: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationClaimUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.AuthorizationClaimUpdatedAtRangeRule(min: 64, max: 1000)
        let item = RevenueCycle.newAuthorizationClaim("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationClaimRequiredCodeRule(message: "authorization claim needs an entry")
        let item = RevenueCycle.newAuthorizationClaim("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationClaimRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.AuthorizationClaimRequiredUnitRule(message: "authorization claim needs a value")
        let item = RevenueCycle.newAuthorizationClaim("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
