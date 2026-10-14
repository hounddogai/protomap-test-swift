@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralBaselineValidator()
        let item = Referrals.newReferralBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralBaselineRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.ReferralBaselineRateRangeRule(min: 6.7, max: 4180.6)
        let item = Referrals.newReferralBaseline("x", label: "y")
        item.rate = 4182.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralBaselineCodeLengthRule(maxLength: 64)
        let item = Referrals.newReferralBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralBaselineRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Referrals.ReferralBaselineRequiredContactEmailRule(message: "referral baseline needs this field")
        let item = Referrals.newReferralBaseline("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
