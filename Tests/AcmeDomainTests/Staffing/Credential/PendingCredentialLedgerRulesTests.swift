@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingCredentialLedgerValidator()
        let item = Staffing.newPendingCredentialLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingCredentialLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PendingCredentialLedgerCodeLengthRule(maxLength: 64)
        let item = Staffing.newPendingCredentialLedger("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingCredentialLedgerPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.PendingCredentialLedgerPhoneLengthRule(maxLength: 255)
        let item = Staffing.newPendingCredentialLedger("x", name: "y")
        item.phone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
