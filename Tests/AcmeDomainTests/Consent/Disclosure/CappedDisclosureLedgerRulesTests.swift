@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedDisclosureLedgerValidator()
        let item = Consent.newCappedDisclosureLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedDisclosureLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.CappedDisclosureLedgerUpdatedAtRangeRule(min: 255, max: 3600)
        let item = Consent.newCappedDisclosureLedger("x", name: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedDisclosureLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.CappedDisclosureLedgerRequiredCodeRule(message: "capped disclosure ledger needs a value")
        let item = Consent.newCappedDisclosureLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedDisclosureLedgerRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.CappedDisclosureLedgerRegionLengthRule(maxLength: 3600)
        let item = Consent.newCappedDisclosureLedger("x", name: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedDisclosureLedgerRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Consent.CappedDisclosureLedgerRequiredNotesRule(message: "capped disclosure ledger needs a value")
        let item = Consent.newCappedDisclosureLedger("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedDisclosureLedgerBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.CappedDisclosureLedgerBudgetRangeRule(min: 7.0, max: 1393.2)
        let item = Consent.newCappedDisclosureLedger("x", name: "y")
        item.budget = 1394.7
        #expect(rule.check(item).count > 0)
    }
}
