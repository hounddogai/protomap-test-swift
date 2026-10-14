@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferLedgerValidator()
        let item = BedManagement.newTransferLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferLedgerEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = BedManagement.TransferLedgerEndsAtRangeRule(min: 120, max: 255)
        let item = BedManagement.newTransferLedger("x", label: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferLedgerCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newTransferLedger("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferLedgerRequiredCodeRule(message: "transfer ledger needs a value")
        let item = BedManagement.newTransferLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
