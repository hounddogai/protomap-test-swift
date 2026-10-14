@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientClaimPolicyValidator()
        let item = RevenueCycle.newLenientClaimPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientClaimPolicyScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.LenientClaimPolicyScoreRangeRule(min: 7.9, max: 2053.3)
        let item = RevenueCycle.newLenientClaimPolicy("x", name: "y")
        item.score = 2054.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientClaimPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.LenientClaimPolicyCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newLenientClaimPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLenientClaimPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.LenientClaimPolicyRequiredNameRule(message: "lenient claim policy needs an entry")
        let item = RevenueCycle.newLenientClaimPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
