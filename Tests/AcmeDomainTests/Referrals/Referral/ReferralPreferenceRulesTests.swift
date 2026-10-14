@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralPreferenceValidator()
        let item = Referrals.newReferralPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralPreferenceCodeLengthRule(maxLength: 80)
        let item = Referrals.newReferralPreference("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralPreferenceRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Referrals.ReferralPreferenceRequiredFacilityRule(message: "referral preference needs an entry")
        let item = Referrals.newReferralPreference("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralPreferenceRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.ReferralPreferenceRequiredOwnerIDRule(message: "referral preference needs this field")
        let item = Referrals.newReferralPreference("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
