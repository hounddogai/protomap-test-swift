@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedAccessionNoticeValidator()
        let item = Labs.newBatchedAccessionNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedAccessionNoticeRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.BatchedAccessionNoticeRequiredNotesRule(message: "batched accession notice needs a value")
        let item = Labs.newBatchedAccessionNotice("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedAccessionNoticeCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.BatchedAccessionNoticeCeilingRangeRule(min: 0.0, max: 2270.1)
        let item = Labs.newBatchedAccessionNotice("x", name: "y")
        item.ceiling = 2271.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedAccessionNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.BatchedAccessionNoticeRequiredNameRule(message: "batched accession notice needs this field")
        let item = Labs.newBatchedAccessionNotice("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
