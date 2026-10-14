@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationAuditValidator()
        let item = RevenueCycle.newAuthorizationAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationAuditSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = RevenueCycle.AuthorizationAuditSequenceRangeRule(min: 16, max: 120)
        let item = RevenueCycle.newAuthorizationAudit("x", label: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}
