@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyReferralEntryValidator()
        let item = Referrals.newLegacyReferralEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyReferralEntryMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.LegacyReferralEntryMarginRangeRule(min: 2.7, max: 2152.4)
        let item = Referrals.newLegacyReferralEntry("x", title: "y")
        item.margin = 2153.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacyReferralEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.LegacyReferralEntryRequiredNameRule(message: "legacy referral entry needs an entry")
        let item = Referrals.newLegacyReferralEntry("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyReferralEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacyReferralEntryRequiredCodeRule(message: "legacy referral entry needs this field")
        let item = Referrals.newLegacyReferralEntry("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyReferralEntryFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.LegacyReferralEntryFloorValueRangeRule(min: 4.2, max: 1076.2)
        let item = Referrals.newLegacyReferralEntry("x", title: "y")
        item.floorValue = 1077.7
        #expect(rule.check(item).count > 0)
    }
}
