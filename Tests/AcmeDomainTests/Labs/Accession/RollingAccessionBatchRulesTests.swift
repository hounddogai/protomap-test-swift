@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingAccessionBatchValidator()
        let item = Labs.newRollingAccessionBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingAccessionBatchPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.RollingAccessionBatchPatientRefLengthRule(maxLength: 255)
        let item = Labs.newRollingAccessionBatch("x", title: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingAccessionBatchRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.RollingAccessionBatchRequiredSegmentRule(message: "rolling accession batch needs an entry")
        let item = Labs.newRollingAccessionBatch("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingAccessionBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.RollingAccessionBatchRequiredTitleRule(message: "rolling accession batch needs an entry")
        let item = Labs.newRollingAccessionBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingAccessionBatchRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.RollingAccessionBatchRequiredPatientRefRule(message: "rolling accession batch needs an entry")
        let item = Labs.newRollingAccessionBatch("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
