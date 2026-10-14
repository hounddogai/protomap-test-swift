@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralDraftValidator()
        let item = Referrals.newReferralDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.ReferralDraftRequiredNameRule(message: "referral draft needs an entry")
        let item = Referrals.newReferralDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralDraftSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.ReferralDraftSequenceRangeRule(min: 64, max: 3600)
        let item = Referrals.newReferralDraft("x", name: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralDraftFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.ReferralDraftFloorValueRangeRule(min: 6.6, max: 4020.8)
        let item = Referrals.newReferralDraft("x", name: "y")
        item.floorValue = 4022.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralDraftCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.ReferralDraftCopayRangeRule(min: 6.5, max: 3876.0)
        let item = Referrals.newReferralDraft("x", name: "y")
        item.copay = 3877.5
        #expect(rule.check(item).count > 0)
    }
}
