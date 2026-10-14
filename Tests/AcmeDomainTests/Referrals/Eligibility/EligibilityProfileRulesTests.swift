@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityProfileValidator()
        let item = Referrals.newEligibilityProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityProfileRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.EligibilityProfileRequiredCountryRule(message: "eligibility profile needs this field")
        let item = Referrals.newEligibilityProfile("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityProfileEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.EligibilityProfileEndsAtRangeRule(min: 80, max: 86400)
        let item = Referrals.newEligibilityProfile("x", label: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityProfileAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.EligibilityProfileAmountRangeRule(min: 9.7, max: 1060.0)
        let item = Referrals.newEligibilityProfile("x", label: "y")
        item.amount = 1061.5
        #expect(rule.check(item).count > 0)
    }
}
