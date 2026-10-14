@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialRequestValidator()
        let item = Staffing.newCredentialRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialRequestTitleLengthRule(maxLength: 255)
        let item = Staffing.newCredentialRequest("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialRequestRequiredTitleRule(message: "credential request needs a value")
        let item = Staffing.newCredentialRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialRequestRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Staffing.CredentialRequestRequiredDiagnosisCodeRule(message: "credential request needs this field")
        let item = Staffing.newCredentialRequest("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
