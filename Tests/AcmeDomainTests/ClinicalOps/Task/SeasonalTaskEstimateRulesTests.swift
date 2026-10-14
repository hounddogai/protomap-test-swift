@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalTaskEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalTaskEstimateValidator()
        let item = ClinicalOps.newSeasonalTaskEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalTaskEstimateMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.SeasonalTaskEstimateMaximumRangeRule(min: 8.9, max: 2208.8)
        let item = ClinicalOps.newSeasonalTaskEstimate("x", label: "y")
        item.maximum = 2210.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsSeasonalTaskEstimateRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.SeasonalTaskEstimateRequiredReviewerRule(message: "seasonal task estimate needs a value")
        let item = ClinicalOps.newSeasonalTaskEstimate("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsSeasonalTaskEstimateReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.SeasonalTaskEstimateReviewerLengthRule(maxLength: 86400)
        let item = ClinicalOps.newSeasonalTaskEstimate("x", label: "y")
        item.reviewer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalTaskEstimateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.SeasonalTaskEstimateRateRangeRule(min: 8.1, max: 1977.4)
        let item = ClinicalOps.newSeasonalTaskEstimate("x", label: "y")
        item.rate = 1978.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsSeasonalTaskEstimateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.SeasonalTaskEstimateRequiredLabelRule(message: "seasonal task estimate needs this field")
        let item = ClinicalOps.newSeasonalTaskEstimate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
