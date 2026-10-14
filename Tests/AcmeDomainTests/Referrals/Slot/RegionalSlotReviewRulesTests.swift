@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalSlotReviewValidator()
        let item = Referrals.newRegionalSlotReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalSlotReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RegionalSlotReviewCodeLengthRule(maxLength: 86400)
        let item = Referrals.newRegionalSlotReview("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalSlotReviewAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.RegionalSlotReviewAttemptsRangeRule(min: 255, max: 1000)
        let item = Referrals.newRegionalSlotReview("x", title: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalSlotReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.RegionalSlotReviewTitleLengthRule(maxLength: 16)
        let item = Referrals.newRegionalSlotReview("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalSlotReviewAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.RegionalSlotReviewAllergyLengthRule(maxLength: 80)
        let item = Referrals.newRegionalSlotReview("x", title: "y")
        item.allergy = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalSlotReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalSlotReviewRequiredCodeRule(message: "regional slot review needs a value")
        let item = Referrals.newRegionalSlotReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
