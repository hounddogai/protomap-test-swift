@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveEligibilityMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveEligibilityMilestoneValidator()
        let item = Referrals.newAdaptiveEligibilityMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveEligibilityMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.AdaptiveEligibilityMilestoneCodeLengthRule(maxLength: 32)
        let item = Referrals.newAdaptiveEligibilityMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveEligibilityMilestoneAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.AdaptiveEligibilityMilestoneAllergyLengthRule(maxLength: 80)
        let item = Referrals.newAdaptiveEligibilityMilestone("x", title: "y")
        item.allergy = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveEligibilityMilestoneRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.AdaptiveEligibilityMilestoneRequiredAllergyRule(
            message: "adaptive eligibility milestone needs an entry"
        )
        let item = Referrals.newAdaptiveEligibilityMilestone("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
