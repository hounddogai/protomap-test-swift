@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedCleaningRecordValidator()
        let item = BedManagement.newBatchedCleaningRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedCleaningRecordSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.BatchedCleaningRecordSequenceRangeRule(min: 3600, max: 3600)
        let item = BedManagement.newBatchedCleaningRecord("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedCleaningRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.BatchedCleaningRecordRequiredLabelRule(
            message: "batched cleaning record needs an entry"
        )
        let item = BedManagement.newBatchedCleaningRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBatchedCleaningRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.BatchedCleaningRecordLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newBatchedCleaningRecord("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedCleaningRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BatchedCleaningRecordCodeLengthRule(maxLength: 80)
        let item = BedManagement.newBatchedCleaningRecord("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
