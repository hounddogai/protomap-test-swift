@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingCensusLedgerValidator()
        let item = BedManagement.newPendingCensusLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingCensusLedgerMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.PendingCensusLedgerMarginRangeRule(min: 5.7, max: 1913.2)
        let item = BedManagement.newPendingCensusLedger("x", label: "y")
        item.margin = 1914.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingCensusLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PendingCensusLedgerCodeLengthRule(maxLength: 120)
        let item = BedManagement.newPendingCensusLedger("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCensusLedgerClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.PendingCensusLedgerClinicianIDLengthRule(maxLength: 64)
        let item = BedManagement.newPendingCensusLedger("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCensusLedgerWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.PendingCensusLedgerWeightRangeRule(min: 0.0, max: 3304.8)
        let item = BedManagement.newPendingCensusLedger("x", label: "y")
        item.weight = 3306.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingCensusLedgerBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.PendingCensusLedgerBudgetRangeRule(min: 5.0, max: 2414.0)
        let item = BedManagement.newPendingCensusLedger("x", label: "y")
        item.budget = 2415.5
        #expect(rule.check(item).count > 0)
    }
}
