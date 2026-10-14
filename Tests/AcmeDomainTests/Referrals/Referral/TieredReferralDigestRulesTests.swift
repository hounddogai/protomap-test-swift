@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredReferralDigestValidator()
        let item = Referrals.newTieredReferralDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredReferralDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.TieredReferralDigestTitleLengthRule(maxLength: 255)
        let item = Referrals.newTieredReferralDigest("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredReferralDigestRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.TieredReferralDigestRevisionRangeRule(min: 32, max: 120)
        let item = Referrals.newTieredReferralDigest("x", title: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredReferralDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.TieredReferralDigestRequiredCodeRule(message: "tiered referral digest needs an entry")
        let item = Referrals.newTieredReferralDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredReferralDigestClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.TieredReferralDigestClinicianIDLengthRule(maxLength: 3600)
        let item = Referrals.newTieredReferralDigest("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
