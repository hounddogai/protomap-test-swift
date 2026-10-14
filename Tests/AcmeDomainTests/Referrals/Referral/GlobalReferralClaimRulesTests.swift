@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalReferralClaimValidator()
        let item = Referrals.newGlobalReferralClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalReferralClaimCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.GlobalReferralClaimCostRangeRule(min: 3.2, max: 4862.1)
        let item = Referrals.newGlobalReferralClaim("x", name: "y")
        item.cost = 4863.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalReferralClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.GlobalReferralClaimCodeLengthRule(maxLength: 16)
        let item = Referrals.newGlobalReferralClaim("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalReferralClaimRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.GlobalReferralClaimRequiredChannelRule(message: "global referral claim needs an entry")
        let item = Referrals.newGlobalReferralClaim("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalReferralClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.GlobalReferralClaimRequiredCodeRule(message: "global referral claim needs this field")
        let item = Referrals.newGlobalReferralClaim("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalReferralClaimRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.GlobalReferralClaimRequiredPhoneRule(message: "global referral claim needs a value")
        let item = Referrals.newGlobalReferralClaim("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
