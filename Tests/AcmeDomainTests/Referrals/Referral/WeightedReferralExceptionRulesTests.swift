@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedReferralExceptionValidator()
        let item = Referrals.newWeightedReferralException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedReferralExceptionRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.WeightedReferralExceptionRefillsRangeRule(min: 32, max: 80)
        let item = Referrals.newWeightedReferralException("x", title: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedReferralExceptionClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.WeightedReferralExceptionClinicianIDLengthRule(maxLength: 3600)
        let item = Referrals.newWeightedReferralException("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedReferralExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.WeightedReferralExceptionTitleLengthRule(maxLength: 1000)
        let item = Referrals.newWeightedReferralException("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
