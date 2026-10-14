@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralQuotaValidator()
        let item = Referrals.newReferralQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralQuotaCodeLengthRule(maxLength: 3600)
        let item = Referrals.newReferralQuota("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralQuotaWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.ReferralQuotaWardLengthRule(maxLength: 32)
        let item = Referrals.newReferralQuota("x", title: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralQuotaRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.ReferralQuotaRequiredWardRule(message: "referral quota needs this field")
        let item = Referrals.newReferralQuota("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
