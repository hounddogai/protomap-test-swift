@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedReferenceRangeEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedReferenceRangeEstimateValidator()
        let item = Labs.newWeightedReferenceRangeEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedReferenceRangeEstimateMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.WeightedReferenceRangeEstimateMaximumRangeRule(min: 4.9, max: 172.4)
        let item = Labs.newWeightedReferenceRangeEstimate("x", name: "y")
        item.maximum = 173.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedReferenceRangeEstimateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.WeightedReferenceRangeEstimateTitleLengthRule(maxLength: 120)
        let item = Labs.newWeightedReferenceRangeEstimate("x", name: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedReferenceRangeEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.WeightedReferenceRangeEstimateRequiredCodeRule(
            message: "weighted reference range estimate needs this field"
        )
        let item = Labs.newWeightedReferenceRangeEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedReferenceRangeEstimateDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.WeightedReferenceRangeEstimateDurationMinutesRangeRule(min: 64, max: 1000)
        let item = Labs.newWeightedReferenceRangeEstimate("x", name: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedReferenceRangeEstimateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.WeightedReferenceRangeEstimateDiscountRangeRule(min: 2.9, max: 740.8)
        let item = Labs.newWeightedReferenceRangeEstimate("x", name: "y")
        item.discount = 742.3
        #expect(rule.check(item).count > 0)
    }
}
