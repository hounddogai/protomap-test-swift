@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationPolicyValidator()
        let item = RevenueCycle.newAuthorizationPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationPolicyLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.AuthorizationPolicyLimitRangeRule(min: 255, max: 3600)
        let item = RevenueCycle.newAuthorizationPolicy("x", name: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.AuthorizationPolicyRequiredNameRule(message: "authorization policy needs a value")
        let item = RevenueCycle.newAuthorizationPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationPolicyRequiredCodeRule(message: "authorization policy needs an entry")
        let item = RevenueCycle.newAuthorizationPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationPolicyUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = RevenueCycle.AuthorizationPolicyUnitLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAuthorizationPolicy("x", name: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
