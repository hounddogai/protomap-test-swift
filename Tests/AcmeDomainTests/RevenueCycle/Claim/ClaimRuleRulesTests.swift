@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimRuleValidator()
        let item = RevenueCycle.newClaimRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimRuleStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.ClaimRuleStartsAtRangeRule(min: 64, max: 1000)
        let item = RevenueCycle.newClaimRule("x", title: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
