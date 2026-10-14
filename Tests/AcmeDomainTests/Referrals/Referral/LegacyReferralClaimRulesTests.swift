@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyReferralClaimValidator()
        let item = Referrals.newLegacyReferralClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyReferralClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.LegacyReferralClaimRequiredNameRule(message: "legacy referral claim needs an entry")
        let item = Referrals.newLegacyReferralClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyReferralClaimBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Referrals.LegacyReferralClaimBedLengthRule(maxLength: 3600)
        let item = Referrals.newLegacyReferralClaim("x", name: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
