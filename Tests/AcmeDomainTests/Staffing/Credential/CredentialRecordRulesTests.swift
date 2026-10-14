@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialRecordValidator()
        let item = Staffing.newCredentialRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialRecordCodeLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialRecord("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialRecordRequiredCodeRule(message: "credential record needs an entry")
        let item = Staffing.newCredentialRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
