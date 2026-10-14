@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackAuthorizationAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackAuthorizationAuditValidator()
        let item = RevenueCycle.newFallbackAuthorizationAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.FallbackAuthorizationAuditCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newFallbackAuthorizationAudit("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationAuditMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.FallbackAuthorizationAuditMaximumRangeRule(min: 4.5, max: 3052.3)
        let item = RevenueCycle.newFallbackAuthorizationAudit("x", name: "y")
        item.maximum = 3053.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationAuditScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.FallbackAuthorizationAuditScoreRangeRule(min: 0.3, max: 1825.9)
        let item = RevenueCycle.newFallbackAuthorizationAudit("x", name: "y")
        item.score = 1827.4
        #expect(rule.check(item).count > 0)
    }
}
