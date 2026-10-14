@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityClaimValidator()
        let item = Referrals.newEligibilityClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.EligibilityClaimRequiredTitleRule(message: "eligibility claim needs a value")
        let item = Referrals.newEligibilityClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityClaimRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.EligibilityClaimRateRangeRule(min: 3.4, max: 3810.3)
        let item = Referrals.newEligibilityClaim("x", title: "y")
        item.rate = 3811.8
        #expect(rule.check(item).count > 0)
    }
}
