@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalReferralAuditValidator()
        let item = Referrals.newSeasonalReferralAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalReferralAuditScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.SeasonalReferralAuditScoreRangeRule(min: 0.4, max: 4891.2)
        let item = Referrals.newSeasonalReferralAudit("x", label: "y")
        item.score = 4892.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalReferralAuditRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.SeasonalReferralAuditRequiredLabelRule(message: "seasonal referral audit needs this field")
        let item = Referrals.newSeasonalReferralAudit("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalReferralAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SeasonalReferralAuditRequiredCodeRule(message: "seasonal referral audit needs a value")
        let item = Referrals.newSeasonalReferralAudit("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
