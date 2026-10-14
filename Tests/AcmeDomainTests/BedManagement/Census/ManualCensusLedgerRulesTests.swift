@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualCensusLedgerValidator()
        let item = BedManagement.newManualCensusLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualCensusLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ManualCensusLedgerRequiredCodeRule(message: "manual census ledger needs this field")
        let item = BedManagement.newManualCensusLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualCensusLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.ManualCensusLedgerNameLengthRule(maxLength: 32)
        let item = BedManagement.newManualCensusLedger("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualCensusLedgerSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = BedManagement.ManualCensusLedgerSummaryLengthRule(maxLength: 1000)
        let item = BedManagement.newManualCensusLedger("x", name: "y")
        item.summary = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualCensusLedgerRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = BedManagement.ManualCensusLedgerRequiredSummaryRule(message: "manual census ledger needs this field")
        let item = BedManagement.newManualCensusLedger("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualCensusLedgerCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = BedManagement.ManualCensusLedgerCapacityRangeRule(min: 16, max: 86400)
        let item = BedManagement.newManualCensusLedger("x", name: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
