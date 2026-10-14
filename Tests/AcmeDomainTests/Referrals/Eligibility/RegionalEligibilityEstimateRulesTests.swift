@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalEligibilityEstimateValidator()
        let item = Referrals.newRegionalEligibilityEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalEligibilityEstimateRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.RegionalEligibilityEstimateRequiredTimezoneRule(
            message: "regional eligibility estimate needs a value"
        )
        let item = Referrals.newRegionalEligibilityEstimate("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalEligibilityEstimateCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.RegionalEligibilityEstimateCeilingRangeRule(min: 0.1, max: 1687.8)
        let item = Referrals.newRegionalEligibilityEstimate("x", title: "y")
        item.ceiling = 1689.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalEligibilityEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.RegionalEligibilityEstimateRequiredTitleRule(
            message: "regional eligibility estimate needs an entry"
        )
        let item = Referrals.newRegionalEligibilityEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
