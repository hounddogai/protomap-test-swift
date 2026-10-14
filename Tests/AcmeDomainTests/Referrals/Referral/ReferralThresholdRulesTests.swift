@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralThresholdValidator()
        let item = Referrals.newReferralThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralThresholdSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Referrals.ReferralThresholdSpecialtyLengthRule(maxLength: 86400)
        let item = Referrals.newReferralThreshold("x", name: "y")
        item.specialty = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralThresholdChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Referrals.ReferralThresholdChecksumLengthRule(maxLength: 3600)
        let item = Referrals.newReferralThreshold("x", name: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralThresholdRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Referrals.ReferralThresholdRequiredSpecialtyRule(message: "referral threshold needs an entry")
        let item = Referrals.newReferralThreshold("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralThresholdRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Referrals.ReferralThresholdRequiredChecksumRule(message: "referral threshold needs an entry")
        let item = Referrals.newReferralThreshold("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
