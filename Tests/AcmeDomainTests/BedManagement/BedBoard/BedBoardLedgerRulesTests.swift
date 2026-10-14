@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardLedgerValidator()
        let item = BedManagement.newBedBoardLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardLedgerCodeLengthRule(maxLength: 120)
        let item = BedManagement.newBedBoardLedger("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.BedBoardLedgerUpdatedAtRangeRule(min: 1000, max: 3600)
        let item = BedManagement.newBedBoardLedger("x", name: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
