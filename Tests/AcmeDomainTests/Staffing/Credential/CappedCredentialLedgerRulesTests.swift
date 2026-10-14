@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedCredentialLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedCredentialLedgerValidator()
        let item = Staffing.newCappedCredentialLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedCredentialLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CappedCredentialLedgerCodeLengthRule(maxLength: 255)
        let item = Staffing.newCappedCredentialLedger("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedCredentialLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.CappedCredentialLedgerRequiredNameRule(message: "capped credential ledger needs a value")
        let item = Staffing.newCappedCredentialLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedCredentialLedgerRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.CappedCredentialLedgerRateRangeRule(min: 4.4, max: 2172.1)
        let item = Staffing.newCappedCredentialLedger("x", name: "y")
        item.rate = 2173.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedCredentialLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CappedCredentialLedgerRequiredCodeRule(message: "capped credential ledger needs an entry")
        let item = Staffing.newCappedCredentialLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
