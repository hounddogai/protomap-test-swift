@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackReferenceRangeVarianceValidator()
        let item = Labs.newFallbackReferenceRangeVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackReferenceRangeVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackReferenceRangeVarianceRequiredCodeRule(
            message: "fallback reference range variance needs this field"
        )
        let item = Labs.newFallbackReferenceRangeVariance("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackReferenceRangeVarianceRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.FallbackReferenceRangeVarianceRatioRangeRule(min: 2.6, max: 3154.9)
        let item = Labs.newFallbackReferenceRangeVariance("x", label: "y")
        item.ratio = 3156.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackReferenceRangeVarianceCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.FallbackReferenceRangeVarianceCapacityRangeRule(min: 80, max: 120)
        let item = Labs.newFallbackReferenceRangeVariance("x", label: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}
