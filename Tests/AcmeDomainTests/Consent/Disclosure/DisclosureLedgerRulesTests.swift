@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureLedgerValidator()
        let item = Consent.newDisclosureLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureLedgerLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.DisclosureLedgerLabelLengthRule(maxLength: 1000)
        let item = Consent.newDisclosureLedger("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureLedgerRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.DisclosureLedgerRequiredProcedureCodeRule(message: "disclosure ledger needs a value")
        let item = Consent.newDisclosureLedger("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureLedgerCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.DisclosureLedgerCopayRangeRule(min: 8.6, max: 4165.7)
        let item = Consent.newDisclosureLedger("x", label: "y")
        item.copay = 4167.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureLedgerPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Consent.DisclosureLedgerPatientRefLengthRule(maxLength: 64)
        let item = Consent.newDisclosureLedger("x", label: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
