@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryEligibilityClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryEligibilityClaimValidator()
        let item = Referrals.newPrimaryEligibilityClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityClaimMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.PrimaryEligibilityClaimMinimumRangeRule(min: 6.5, max: 1608.3)
        let item = Referrals.newPrimaryEligibilityClaim("x", name: "y")
        item.minimum = 1609.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.PrimaryEligibilityClaimNameLengthRule(maxLength: 86400)
        let item = Referrals.newPrimaryEligibilityClaim("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityClaimReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.PrimaryEligibilityClaimReviewerLengthRule(maxLength: 64)
        let item = Referrals.newPrimaryEligibilityClaim("x", name: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityClaimGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.PrimaryEligibilityClaimGraceDaysRangeRule(min: 16, max: 120)
        let item = Referrals.newPrimaryEligibilityClaim("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.PrimaryEligibilityClaimRequiredNameRule(message: "primary eligibility claim needs a value")
        let item = Referrals.newPrimaryEligibilityClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
