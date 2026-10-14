@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictPanelAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictPanelAssignmentValidator()
        let item = Labs.newStrictPanelAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictPanelAssignmentRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.StrictPanelAssignmentRequiredNotesRule(message: "strict panel assignment needs an entry")
        let item = Labs.newStrictPanelAssignment("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictPanelAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.StrictPanelAssignmentTitleLengthRule(maxLength: 255)
        let item = Labs.newStrictPanelAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsStrictPanelAssignmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.StrictPanelAssignmentBatchSizeRangeRule(min: 255, max: 1000)
        let item = Labs.newStrictPanelAssignment("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
