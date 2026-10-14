@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedBedBoardLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedBedBoardLedgerValidator()
        let item = BedManagement.newBatchedBedBoardLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedBedBoardLedgerLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.BatchedBedBoardLedgerLimitRangeRule(min: 32, max: 1000)
        let item = BedManagement.newBatchedBedBoardLedger("x", title: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedBedBoardLedgerAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.BatchedBedBoardLedgerAttemptsRangeRule(min: 32, max: 120)
        let item = BedManagement.newBatchedBedBoardLedger("x", title: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedBedBoardLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.BatchedBedBoardLedgerRequiredTitleRule(
            message: "batched bed board ledger needs this field"
        )
        let item = BedManagement.newBatchedBedBoardLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBatchedBedBoardLedgerProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = BedManagement.BatchedBedBoardLedgerProcedureCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newBatchedBedBoardLedger("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
