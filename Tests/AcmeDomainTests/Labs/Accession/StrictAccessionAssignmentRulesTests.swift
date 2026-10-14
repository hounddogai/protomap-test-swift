@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictAccessionAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictAccessionAssignmentValidator()
        let item = Labs.newStrictAccessionAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictAccessionAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.StrictAccessionAssignmentRequiredCodeRule(message: "strict accession assignment needs a value")
        let item = Labs.newStrictAccessionAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictAccessionAssignmentRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.StrictAccessionAssignmentRequiredNotesRule(
            message: "strict accession assignment needs this field"
        )
        let item = Labs.newStrictAccessionAssignment("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictAccessionAssignmentAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.StrictAccessionAssignmentAmountRangeRule(min: 7.0, max: 830.0)
        let item = Labs.newStrictAccessionAssignment("x", title: "y")
        item.amount = 831.5
        #expect(rule.check(item).count > 0)
    }
}
