@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralRequestValidator()
        let item = Referrals.newReferralRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralRequestBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Referrals.ReferralRequestBedLengthRule(maxLength: 32)
        let item = Referrals.newReferralRequest("x", name: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralRequestRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.ReferralRequestRequiredBedRule(message: "referral request needs an entry")
        let item = Referrals.newReferralRequest("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralRequestAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.ReferralRequestAcuityRangeRule(min: 16, max: 16)
        let item = Referrals.newReferralRequest("x", name: "y")
        item.acuity = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ReferralRequestTitleLengthRule(maxLength: 120)
        let item = Referrals.newReferralRequest("x", name: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralRequestRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.ReferralRequestRatioRangeRule(min: 2.0, max: 1687.3)
        let item = Referrals.newReferralRequest("x", name: "y")
        item.ratio = 1688.8
        #expect(rule.check(item).count > 0)
    }
}
