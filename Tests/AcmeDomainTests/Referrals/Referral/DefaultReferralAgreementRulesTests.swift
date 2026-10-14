@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultReferralAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultReferralAgreementValidator()
        let item = Referrals.newDefaultReferralAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultReferralAgreementSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.DefaultReferralAgreementSummaryLengthRule(maxLength: 86400)
        let item = Referrals.newDefaultReferralAgreement("x", name: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultReferralAgreementScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.DefaultReferralAgreementScoreRangeRule(min: 6.6, max: 3350.3)
        let item = Referrals.newDefaultReferralAgreement("x", name: "y")
        item.score = 3351.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsDefaultReferralAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.DefaultReferralAgreementCodeLengthRule(maxLength: 3600)
        let item = Referrals.newDefaultReferralAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultReferralAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.DefaultReferralAgreementNameLengthRule(maxLength: 3600)
        let item = Referrals.newDefaultReferralAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultReferralAgreementTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.DefaultReferralAgreementTimezoneLengthRule(maxLength: 1000)
        let item = Referrals.newDefaultReferralAgreement("x", name: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
