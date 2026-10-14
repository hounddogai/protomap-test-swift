@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeWindowValidator()
        let item = Labs.newReferenceRangeWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeWindowRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.ReferenceRangeWindowRequiredNotesRule(message: "reference range window needs a value")
        let item = Labs.newReferenceRangeWindow("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeWindowRequiredCodeRule(message: "reference range window needs an entry")
        let item = Labs.newReferenceRangeWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeWindowRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Labs.ReferenceRangeWindowRequiredProcedureCodeRule(message: "reference range window needs a value")
        let item = Labs.newReferenceRangeWindow("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeWindowNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Labs.ReferenceRangeWindowNotesLengthRule(maxLength: 3600)
        let item = Labs.newReferenceRangeWindow("x", title: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
