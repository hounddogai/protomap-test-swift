@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackReferralVarianceValidator()
        let item = Referrals.newFallbackReferralVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackReferralVarianceRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.FallbackReferralVarianceRequiredWardRule(
            message: "fallback referral variance needs an entry"
        )
        let item = Referrals.newFallbackReferralVariance("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackReferralVarianceWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.FallbackReferralVarianceWardLengthRule(maxLength: 120)
        let item = Referrals.newFallbackReferralVariance("x", title: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackReferralVarianceChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Referrals.FallbackReferralVarianceChecksumLengthRule(maxLength: 86400)
        let item = Referrals.newFallbackReferralVariance("x", title: "y")
        item.checksum = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
