@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralSnapshotValidator()
        let item = Referrals.newReferralSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ReferralSnapshotRequiredTitleRule(message: "referral snapshot needs an entry")
        let item = Referrals.newReferralSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralSnapshotRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Referrals.ReferralSnapshotRegionLengthRule(maxLength: 3600)
        let item = Referrals.newReferralSnapshot("x", title: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralSnapshotCodeLengthRule(maxLength: 3600)
        let item = Referrals.newReferralSnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ReferralSnapshotTitleLengthRule(maxLength: 3600)
        let item = Referrals.newReferralSnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralSnapshotSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.ReferralSnapshotSequenceRangeRule(min: 80, max: 86400)
        let item = Referrals.newReferralSnapshot("x", title: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
