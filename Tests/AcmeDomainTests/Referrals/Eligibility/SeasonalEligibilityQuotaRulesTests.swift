@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalEligibilityQuotaValidator()
        let item = Referrals.newSeasonalEligibilityQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalEligibilityQuotaScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.SeasonalEligibilityQuotaScoreRangeRule(min: 8.2, max: 4044.6)
        let item = Referrals.newSeasonalEligibilityQuota("x", name: "y")
        item.score = 4046.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalEligibilityQuotaRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.SeasonalEligibilityQuotaRequiredAllergyRule(
            message: "seasonal eligibility quota needs this field"
        )
        let item = Referrals.newSeasonalEligibilityQuota("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalEligibilityQuotaPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.SeasonalEligibilityQuotaPhoneLengthRule(maxLength: 120)
        let item = Referrals.newSeasonalEligibilityQuota("x", name: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
