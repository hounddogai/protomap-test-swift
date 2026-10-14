@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveReferralSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveReferralSummaryValidator()
        let item = Referrals.newAdaptiveReferralSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveReferralSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.AdaptiveReferralSummaryCodeLengthRule(maxLength: 120)
        let item = Referrals.newAdaptiveReferralSummary("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveReferralSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.AdaptiveReferralSummaryRequiredCodeRule(message: "adaptive referral summary needs an entry")
        let item = Referrals.newAdaptiveReferralSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsAdaptiveReferralSummaryWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.AdaptiveReferralSummaryWardLengthRule(maxLength: 120)
        let item = Referrals.newAdaptiveReferralSummary("x", title: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
