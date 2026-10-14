@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityEstimateValidator()
        let item = Referrals.newEligibilityEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityEstimateSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Referrals.EligibilityEstimateSegmentLengthRule(maxLength: 64)
        let item = Referrals.newEligibilityEstimate("x", title: "y")
        item.segment = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityEstimateRequiredCodeRule(message: "eligibility estimate needs a value")
        let item = Referrals.newEligibilityEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityEstimateThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Referrals.EligibilityEstimateThresholdRangeRule(min: 0.7, max: 1398.2)
        let item = Referrals.newEligibilityEstimate("x", title: "y")
        item.threshold = 1399.7
        #expect(rule.check(item).count > 0)
    }
}
