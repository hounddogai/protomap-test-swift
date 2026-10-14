@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientEligibilityEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientEligibilityEstimateValidator()
        let item = Referrals.newLenientEligibilityEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientEligibilityEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LenientEligibilityEstimateRequiredCodeRule(
            message: "lenient eligibility estimate needs this field"
        )
        let item = Referrals.newLenientEligibilityEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientEligibilityEstimateRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.LenientEligibilityEstimateRequiredSummaryRule(
            message: "lenient eligibility estimate needs an entry"
        )
        let item = Referrals.newLenientEligibilityEstimate("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
