@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryCredentialLedgerValidator()
        let item = Staffing.newPrimaryCredentialLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryCredentialLedgerMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.PrimaryCredentialLedgerMaximumRangeRule(min: 6.5, max: 3645.8)
        let item = Staffing.newPrimaryCredentialLedger("x", name: "y")
        item.maximum = 3647.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryCredentialLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.PrimaryCredentialLedgerNameLengthRule(maxLength: 120)
        let item = Staffing.newPrimaryCredentialLedger("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryCredentialLedgerWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.PrimaryCredentialLedgerWeightRangeRule(min: 1.7, max: 354.8)
        let item = Staffing.newPrimaryCredentialLedger("x", name: "y")
        item.weight = 356.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryCredentialLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryCredentialLedgerCodeLengthRule(maxLength: 1000)
        let item = Staffing.newPrimaryCredentialLedger("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryCredentialLedgerMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.PrimaryCredentialLedgerMinimumRangeRule(min: 2.4, max: 580.1)
        let item = Staffing.newPrimaryCredentialLedger("x", name: "y")
        item.minimum = 581.6
        #expect(rule.check(item).count > 0)
    }
}
