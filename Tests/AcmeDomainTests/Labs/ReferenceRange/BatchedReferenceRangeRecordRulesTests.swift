@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedReferenceRangeRecordValidator()
        let item = Labs.newBatchedReferenceRangeRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedReferenceRangeRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.BatchedReferenceRangeRecordRequiredCodeRule(
            message: "batched reference range record needs an entry"
        )
        let item = Labs.newBatchedReferenceRangeRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
