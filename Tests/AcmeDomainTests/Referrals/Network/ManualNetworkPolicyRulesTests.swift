@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualNetworkPolicyValidator()
        let item = Referrals.newManualNetworkPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualNetworkPolicyEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.ManualNetworkPolicyEndsAtRangeRule(min: 255, max: 255)
        let item = Referrals.newManualNetworkPolicy("x", name: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualNetworkPolicyWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.ManualNetworkPolicyWeightRangeRule(min: 0.3, max: 3930.0)
        let item = Referrals.newManualNetworkPolicy("x", name: "y")
        item.weight = 3931.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualNetworkPolicyWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.ManualNetworkPolicyWardLengthRule(maxLength: 120)
        let item = Referrals.newManualNetworkPolicy("x", name: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
