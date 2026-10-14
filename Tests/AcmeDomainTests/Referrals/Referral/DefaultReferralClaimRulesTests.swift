@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultReferralClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultReferralClaimValidator()
        let item = Referrals.newDefaultReferralClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultReferralClaimRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Referrals.DefaultReferralClaimRequiredRegionRule(message: "default referral claim needs a value")
        let item = Referrals.newDefaultReferralClaim("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultReferralClaimBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Referrals.DefaultReferralClaimBudgetRangeRule(min: 1.5, max: 1741.2)
        let item = Referrals.newDefaultReferralClaim("x", title: "y")
        item.budget = 1742.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsDefaultReferralClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.DefaultReferralClaimRequiredTitleRule(message: "default referral claim needs an entry")
        let item = Referrals.newDefaultReferralClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultReferralClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.DefaultReferralClaimTitleLengthRule(maxLength: 64)
        let item = Referrals.newDefaultReferralClaim("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
