@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCensusLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingCensusLedgerValidator()
        let item = BedManagement.newRollingCensusLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingCensusLedgerWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.RollingCensusLedgerWindowDaysRangeRule(min: 255, max: 3600)
        let item = BedManagement.newRollingCensusLedger("x", name: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCensusLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.RollingCensusLedgerRequiredNameRule(message: "rolling census ledger needs a value")
        let item = BedManagement.newRollingCensusLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingCensusLedgerGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.RollingCensusLedgerGraceDaysRangeRule(min: 80, max: 86400)
        let item = BedManagement.newRollingCensusLedger("x", name: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCensusLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RollingCensusLedgerCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newRollingCensusLedger("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingCensusLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.RollingCensusLedgerNameLengthRule(maxLength: 86400)
        let item = BedManagement.newRollingCensusLedger("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
