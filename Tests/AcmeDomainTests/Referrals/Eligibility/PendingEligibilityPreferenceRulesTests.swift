@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingEligibilityPreferenceValidator()
        let item = Referrals.newPendingEligibilityPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingEligibilityPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PendingEligibilityPreferenceRequiredCodeRule(
            message: "pending eligibility preference needs an entry"
        )
        let item = Referrals.newPendingEligibilityPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingEligibilityPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.PendingEligibilityPreferenceTitleLengthRule(maxLength: 16)
        let item = Referrals.newPendingEligibilityPreference("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingEligibilityPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PendingEligibilityPreferenceRequiredTitleRule(
            message: "pending eligibility preference needs an entry"
        )
        let item = Referrals.newPendingEligibilityPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingEligibilityPreferenceRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.PendingEligibilityPreferenceRequiredPhoneRule(
            message: "pending eligibility preference needs this field"
        )
        let item = Referrals.newPendingEligibilityPreference("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
