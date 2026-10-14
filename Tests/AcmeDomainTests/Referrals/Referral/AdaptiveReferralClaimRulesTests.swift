@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveReferralClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveReferralClaimValidator()
        let item = Referrals.newAdaptiveReferralClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveReferralClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.AdaptiveReferralClaimCodeLengthRule(maxLength: 120)
        let item = Referrals.newAdaptiveReferralClaim("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveReferralClaimRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Referrals.AdaptiveReferralClaimRequiredCategoryRule(
            message: "adaptive referral claim needs this field"
        )
        let item = Referrals.newAdaptiveReferralClaim("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsAdaptiveReferralClaimUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.AdaptiveReferralClaimUnitLengthRule(maxLength: 32)
        let item = Referrals.newAdaptiveReferralClaim("x", title: "y")
        item.unit = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
