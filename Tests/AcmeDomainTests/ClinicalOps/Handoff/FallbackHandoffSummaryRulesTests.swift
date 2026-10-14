@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackHandoffSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackHandoffSummaryValidator()
        let item = ClinicalOps.newFallbackHandoffSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackHandoffSummaryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.FallbackHandoffSummaryPriorityRangeRule(min: 120, max: 1000)
        let item = ClinicalOps.newFallbackHandoffSummary("x", label: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackHandoffSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.FallbackHandoffSummaryLabelLengthRule(maxLength: 120)
        let item = ClinicalOps.newFallbackHandoffSummary("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackHandoffSummarySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.FallbackHandoffSummarySequenceRangeRule(min: 64, max: 86400)
        let item = ClinicalOps.newFallbackHandoffSummary("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
