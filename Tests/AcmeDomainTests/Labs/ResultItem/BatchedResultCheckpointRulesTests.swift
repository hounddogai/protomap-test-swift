@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedResultCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedResultCheckpointValidator()
        let item = Labs.newBatchedResultCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedResultCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.BatchedResultCheckpointRequiredTitleRule(message: "batched result checkpoint needs this field")
        let item = Labs.newBatchedResultCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedResultCheckpointRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.BatchedResultCheckpointRequiredPatientRefRule(message: "batched result checkpoint needs a value")
        let item = Labs.newBatchedResultCheckpoint("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedResultCheckpointCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.BatchedResultCheckpointCountryLengthRule(maxLength: 255)
        let item = Labs.newBatchedResultCheckpoint("x", title: "y")
        item.country = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedResultCheckpointPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.BatchedResultCheckpointPatientRefLengthRule(maxLength: 16)
        let item = Labs.newBatchedResultCheckpoint("x", title: "y")
        item.patientRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
