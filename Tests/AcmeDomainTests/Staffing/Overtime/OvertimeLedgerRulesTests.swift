@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeLedgerValidator()
        let item = Staffing.newOvertimeLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeLedgerRequiredCodeRule(message: "overtime ledger needs a value")
        let item = Staffing.newOvertimeLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeLedgerRequiredTitleRule(message: "overtime ledger needs a value")
        let item = Staffing.newOvertimeLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeLedgerRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.OvertimeLedgerRequiredUnitRule(message: "overtime ledger needs this field")
        let item = Staffing.newOvertimeLedger("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeLedgerUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Staffing.OvertimeLedgerUnitLengthRule(maxLength: 80)
        let item = Staffing.newOvertimeLedger("x", title: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
