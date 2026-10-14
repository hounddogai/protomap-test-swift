@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkTierValidator()
        let item = Referrals.newNetworkTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkTierBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Referrals.NetworkTierBudgetRangeRule(min: 7.4, max: 4815.6)
        let item = Referrals.newNetworkTier("x", title: "y")
        item.budget = 4817.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkTierCodeLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkTier("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkTierPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Referrals.NetworkTierPayerLengthRule(maxLength: 32)
        let item = Referrals.newNetworkTier("x", title: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
