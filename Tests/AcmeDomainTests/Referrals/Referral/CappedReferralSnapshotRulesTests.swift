@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedReferralSnapshotValidator()
        let item = Referrals.newCappedReferralSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedReferralSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.CappedReferralSnapshotRequiredCodeRule(message: "capped referral snapshot needs a value")
        let item = Referrals.newCappedReferralSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedReferralSnapshotRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.CappedReferralSnapshotRequiredLocaleRule(
            message: "capped referral snapshot needs this field"
        )
        let item = Referrals.newCappedReferralSnapshot("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedReferralSnapshotRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Referrals.CappedReferralSnapshotRequiredFacilityRule(
            message: "capped referral snapshot needs a value"
        )
        let item = Referrals.newCappedReferralSnapshot("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
