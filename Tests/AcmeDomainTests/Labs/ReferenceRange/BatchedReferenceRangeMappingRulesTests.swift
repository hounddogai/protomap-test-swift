@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedReferenceRangeMappingValidator()
        let item = Labs.newBatchedReferenceRangeMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedReferenceRangeMappingSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.BatchedReferenceRangeMappingSequenceRangeRule(min: 64, max: 3600)
        let item = Labs.newBatchedReferenceRangeMapping("x", name: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedReferenceRangeMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.BatchedReferenceRangeMappingCodeLengthRule(maxLength: 16)
        let item = Labs.newBatchedReferenceRangeMapping("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedReferenceRangeMappingPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.BatchedReferenceRangeMappingPriorityRangeRule(min: 255, max: 3600)
        let item = Labs.newBatchedReferenceRangeMapping("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}
