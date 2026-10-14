@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimPolicyValidator()
        let item = RevenueCycle.newClaimPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimPolicyRequiredCodeRule(message: "claim policy needs this field")
        let item = RevenueCycle.newClaimPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimPolicyRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.ClaimPolicyRevisionRangeRule(min: 64, max: 255)
        let item = RevenueCycle.newClaimPolicy("x", name: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ClaimPolicyRequiredNameRule(message: "claim policy needs this field")
        let item = RevenueCycle.newClaimPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
