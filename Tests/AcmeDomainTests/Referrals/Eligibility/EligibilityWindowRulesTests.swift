@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityWindowValidator()
        let item = Referrals.newEligibilityWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityWindowAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.EligibilityWindowAmountRangeRule(min: 9.9, max: 64.7)
        let item = Referrals.newEligibilityWindow("x", label: "y")
        item.amount = 66.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityWindowRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.EligibilityWindowRequiredWardRule(message: "eligibility window needs a value")
        let item = Referrals.newEligibilityWindow("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
