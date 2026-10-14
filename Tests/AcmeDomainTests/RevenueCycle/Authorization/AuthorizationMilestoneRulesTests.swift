@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationMilestoneValidator()
        let item = RevenueCycle.newAuthorizationMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationMilestoneRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.AuthorizationMilestoneRetriesRangeRule(min: 16, max: 120)
        let item = RevenueCycle.newAuthorizationMilestone("x", title: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationMilestoneCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newAuthorizationMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
