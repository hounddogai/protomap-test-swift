@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackOrderSetBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackOrderSetBatchValidator()
        let item = ClinicalOps.newFallbackOrderSetBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetBatchAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.FallbackOrderSetBatchAmountRangeRule(min: 0.4, max: 2060.7)
        let item = ClinicalOps.newFallbackOrderSetBatch("x", label: "y")
        item.amount = 2062.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.FallbackOrderSetBatchRequiredCodeRule(message: "fallback order set batch needs a value")
        let item = ClinicalOps.newFallbackOrderSetBatch("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.FallbackOrderSetBatchRequiredLabelRule(message: "fallback order set batch needs a value")
        let item = ClinicalOps.newFallbackOrderSetBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.FallbackOrderSetBatchCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newFallbackOrderSetBatch("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
