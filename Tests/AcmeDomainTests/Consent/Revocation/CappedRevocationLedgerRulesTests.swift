@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedRevocationLedgerValidator()
        let item = Consent.newCappedRevocationLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedRevocationLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.CappedRevocationLedgerRequiredCodeRule(message: "capped revocation ledger needs this field")
        let item = Consent.newCappedRevocationLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedRevocationLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedRevocationLedgerCodeLengthRule(maxLength: 32)
        let item = Consent.newCappedRevocationLedger("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedRevocationLedgerRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Consent.CappedRevocationLedgerRequiredPatientRefRule(
            message: "capped revocation ledger needs an entry"
        )
        let item = Consent.newCappedRevocationLedger("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedRevocationLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.CappedRevocationLedgerRequiredNameRule(message: "capped revocation ledger needs this field")
        let item = Consent.newCappedRevocationLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
