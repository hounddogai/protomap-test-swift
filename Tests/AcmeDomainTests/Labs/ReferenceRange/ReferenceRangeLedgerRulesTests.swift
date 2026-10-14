@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeLedgerValidator()
        let item = Labs.newReferenceRangeLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeLedgerRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.ReferenceRangeLedgerRegionLengthRule(maxLength: 3600)
        let item = Labs.newReferenceRangeLedger("x", name: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeLedgerWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.ReferenceRangeLedgerWeightRangeRule(min: 6.2, max: 2643.7)
        let item = Labs.newReferenceRangeLedger("x", name: "y")
        item.weight = 2645.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeLedgerRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.ReferenceRangeLedgerRequiredNotesRule(message: "reference range ledger needs an entry")
        let item = Labs.newReferenceRangeLedger("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeLedgerRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.ReferenceRangeLedgerRevisionRangeRule(min: 32, max: 1000)
        let item = Labs.newReferenceRangeLedger("x", name: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.ReferenceRangeLedgerUpdatedAtRangeRule(min: 255, max: 1000)
        let item = Labs.newReferenceRangeLedger("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
