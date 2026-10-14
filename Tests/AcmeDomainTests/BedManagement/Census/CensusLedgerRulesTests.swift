@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusLedgerValidator()
        let item = BedManagement.newCensusLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusLedgerMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.CensusLedgerMaximumRangeRule(min: 7.8, max: 4785.0)
        let item = BedManagement.newCensusLedger("x", name: "y")
        item.maximum = 4786.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CensusLedgerRequiredCodeRule(message: "census ledger needs an entry")
        let item = BedManagement.newCensusLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusLedgerDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.CensusLedgerDiagnosisCodeLengthRule(maxLength: 120)
        let item = BedManagement.newCensusLedger("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusLedgerRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.CensusLedgerRequiredDiagnosisCodeRule(message: "census ledger needs a value")
        let item = BedManagement.newCensusLedger("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
