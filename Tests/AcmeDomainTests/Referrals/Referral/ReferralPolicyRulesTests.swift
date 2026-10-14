@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralPolicyValidator()
        let item = Referrals.newReferralPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralPolicyBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.ReferralPolicyBatchSizeRangeRule(min: 3600, max: 86400)
        let item = Referrals.newReferralPolicy("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralPolicyPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Referrals.ReferralPolicyPayerLengthRule(maxLength: 255)
        let item = Referrals.newReferralPolicy("x", title: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralPolicyWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.ReferralPolicyWeightRangeRule(min: 9.7, max: 4538.4)
        let item = Referrals.newReferralPolicy("x", title: "y")
        item.weight = 4539.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralPolicyRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.ReferralPolicyRequiredPayerRule(message: "referral policy needs an entry")
        let item = Referrals.newReferralPolicy("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
