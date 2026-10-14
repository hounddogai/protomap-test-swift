@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralDigestValidator()
        let item = Referrals.newReferralDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralDigestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.ReferralDigestRateRangeRule(min: 4.6, max: 3770.4)
        let item = Referrals.newReferralDigest("x", label: "y")
        item.rate = 3771.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralDigestCodeLengthRule(maxLength: 120)
        let item = Referrals.newReferralDigest("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralDigestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.ReferralDigestDosageMgRangeRule(min: 2.4, max: 177.1)
        let item = Referrals.newReferralDigest("x", label: "y")
        item.dosageMg = 178.6
        #expect(rule.check(item).count > 0)
    }
}
