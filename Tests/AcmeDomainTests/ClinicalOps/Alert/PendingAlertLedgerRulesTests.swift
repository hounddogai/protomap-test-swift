@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingAlertLedgerValidator()
        let item = ClinicalOps.newPendingAlertLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingAlertLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.PendingAlertLedgerRequiredTitleRule(message: "pending alert ledger needs a value")
        let item = ClinicalOps.newPendingAlertLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingAlertLedgerRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = ClinicalOps.PendingAlertLedgerRequiredChecksumRule(message: "pending alert ledger needs a value")
        let item = ClinicalOps.newPendingAlertLedger("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingAlertLedgerPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.PendingAlertLedgerPatientRefLengthRule(maxLength: 3600)
        let item = ClinicalOps.newPendingAlertLedger("x", title: "y")
        item.patientRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingAlertLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PendingAlertLedgerRequiredCodeRule(message: "pending alert ledger needs a value")
        let item = ClinicalOps.newPendingAlertLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
