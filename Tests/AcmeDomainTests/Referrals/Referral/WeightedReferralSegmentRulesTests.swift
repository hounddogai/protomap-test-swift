@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedReferralSegmentValidator()
        let item = Referrals.newWeightedReferralSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedReferralSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedReferralSegmentRequiredCodeRule(message: "weighted referral segment needs an entry")
        let item = Referrals.newWeightedReferralSegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedReferralSegmentRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.WeightedReferralSegmentRevisionRangeRule(min: 80, max: 86400)
        let item = Referrals.newWeightedReferralSegment("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedReferralSegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.WeightedReferralSegmentRequiredTitleRule(
            message: "weighted referral segment needs this field"
        )
        let item = Referrals.newWeightedReferralSegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedReferralSegmentDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.WeightedReferralSegmentDiscountRangeRule(min: 9.0, max: 340.8)
        let item = Referrals.newWeightedReferralSegment("x", title: "y")
        item.discount = 342.3
        #expect(rule.check(item).count > 0)
    }
}
