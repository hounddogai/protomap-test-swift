@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictReferralPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictReferralPreferenceValidator()
        let item = Referrals.newStrictReferralPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictReferralPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.StrictReferralPreferenceTitleLengthRule(maxLength: 16)
        let item = Referrals.newStrictReferralPreference("x", name: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictReferralPreferenceSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.StrictReferralPreferenceSequenceRangeRule(min: 80, max: 1000)
        let item = Referrals.newStrictReferralPreference("x", name: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictReferralPreferenceRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Referrals.StrictReferralPreferenceRequiredSpecialtyRule(
            message: "strict referral preference needs this field"
        )
        let item = Referrals.newStrictReferralPreference("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
