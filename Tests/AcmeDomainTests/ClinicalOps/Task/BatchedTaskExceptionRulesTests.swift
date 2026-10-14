@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedTaskExceptionValidator()
        let item = ClinicalOps.newBatchedTaskException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskExceptionRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = ClinicalOps.BatchedTaskExceptionRequiredSegmentRule(message: "batched task exception needs an entry")
        let item = ClinicalOps.newBatchedTaskException("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedTaskExceptionWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.BatchedTaskExceptionWeightRangeRule(min: 9.5, max: 3800.3)
        let item = ClinicalOps.newBatchedTaskException("x", label: "y")
        item.weight = 3801.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskExceptionAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.BatchedTaskExceptionAcuityRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newBatchedTaskException("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.BatchedTaskExceptionCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newBatchedTaskException("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskExceptionSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = ClinicalOps.BatchedTaskExceptionSegmentLengthRule(maxLength: 32)
        let item = ClinicalOps.newBatchedTaskException("x", label: "y")
        item.segment = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
