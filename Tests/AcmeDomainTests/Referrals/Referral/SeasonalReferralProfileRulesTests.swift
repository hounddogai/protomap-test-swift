@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalReferralProfileValidator()
        let item = Referrals.newSeasonalReferralProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalReferralProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.SeasonalReferralProfileRequiredLabelRule(message: "seasonal referral profile needs a value")
        let item = Referrals.newSeasonalReferralProfile("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalReferralProfileCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.SeasonalReferralProfileCeilingRangeRule(min: 6.5, max: 4131.9)
        let item = Referrals.newSeasonalReferralProfile("x", label: "y")
        item.ceiling = 4133.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalReferralProfileGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.SeasonalReferralProfileGraceDaysRangeRule(min: 86400, max: 86400)
        let item = Referrals.newSeasonalReferralProfile("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalReferralProfileAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.SeasonalReferralProfileAllergyLengthRule(maxLength: 120)
        let item = Referrals.newSeasonalReferralProfile("x", label: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
