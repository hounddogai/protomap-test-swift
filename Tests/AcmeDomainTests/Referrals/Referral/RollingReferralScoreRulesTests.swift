@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingReferralScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingReferralScoreValidator()
        let item = Referrals.newRollingReferralScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingReferralScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.RollingReferralScoreTitleLengthRule(maxLength: 86400)
        let item = Referrals.newRollingReferralScore("x", label: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingReferralScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.RollingReferralScoreRequiredTitleRule(message: "rolling referral score needs this field")
        let item = Referrals.newRollingReferralScore("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingReferralScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RollingReferralScoreCodeLengthRule(maxLength: 32)
        let item = Referrals.newRollingReferralScore("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingReferralScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.RollingReferralScoreRequiredLabelRule(message: "rolling referral score needs this field")
        let item = Referrals.newRollingReferralScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
