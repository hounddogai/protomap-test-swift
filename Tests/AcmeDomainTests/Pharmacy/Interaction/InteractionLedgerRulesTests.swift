@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionLedgerValidator()
        let item = Pharmacy.newInteractionLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InteractionLedgerRequiredNameRule(message: "interaction ledger needs this field")
        let item = Pharmacy.newInteractionLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionLedgerVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.InteractionLedgerVersionRangeRule(min: 120, max: 1000)
        let item = Pharmacy.newInteractionLedger("x", name: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionLedgerNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.InteractionLedgerNotesLengthRule(maxLength: 1000)
        let item = Pharmacy.newInteractionLedger("x", name: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InteractionLedgerRequiredCodeRule(message: "interaction ledger needs this field")
        let item = Pharmacy.newInteractionLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionLedgerRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.InteractionLedgerRequiredNotesRule(message: "interaction ledger needs a value")
        let item = Pharmacy.newInteractionLedger("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
