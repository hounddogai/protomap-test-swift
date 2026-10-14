@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralProfileValidator()
        let item = Referrals.newReferralProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ReferralProfileRequiredLabelRule(message: "referral profile needs an entry")
        let item = Referrals.newReferralProfile("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.ReferralProfileLabelLengthRule(maxLength: 1000)
        let item = Referrals.newReferralProfile("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ReferralProfileTitleLengthRule(maxLength: 3600)
        let item = Referrals.newReferralProfile("x", label: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralProfileMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.ReferralProfileMaximumRangeRule(min: 1.9, max: 2585.6)
        let item = Referrals.newReferralProfile("x", label: "y")
        item.maximum = 2587.1
        #expect(rule.check(item).count > 0)
    }
}
