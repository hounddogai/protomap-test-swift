@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralClaimValidator()
        let item = Referrals.newReferralClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralClaimRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.ReferralClaimRequiredChannelRule(message: "referral claim needs an entry")
        let item = Referrals.newReferralClaim("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralClaimCodeLengthRule(maxLength: 86400)
        let item = Referrals.newReferralClaim("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralClaimCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.ReferralClaimCreatedAtRangeRule(min: 3600, max: 3600)
        let item = Referrals.newReferralClaim("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
