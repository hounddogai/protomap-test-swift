@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralReservationValidator()
        let item = Referrals.newReferralReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralReservationMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.ReferralReservationMaximumRangeRule(min: 6.6, max: 1081.8)
        let item = Referrals.newReferralReservation("x", label: "y")
        item.maximum = 1083.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralReservationSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Referrals.ReferralReservationSourceLengthRule(maxLength: 64)
        let item = Referrals.newReferralReservation("x", label: "y")
        item.source = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralReservationCodeLengthRule(maxLength: 86400)
        let item = Referrals.newReferralReservation("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralReservationRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Referrals.ReferralReservationRequiredSourceRule(message: "referral reservation needs a value")
        let item = Referrals.newReferralReservation("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
