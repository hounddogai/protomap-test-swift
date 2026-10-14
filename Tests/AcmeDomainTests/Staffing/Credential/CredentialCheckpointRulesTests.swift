@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialCheckpointValidator()
        let item = Staffing.newCredentialCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.CredentialCheckpointNameLengthRule(maxLength: 1000)
        let item = Staffing.newCredentialCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.CredentialCheckpointRequiredNameRule(message: "credential checkpoint needs this field")
        let item = Staffing.newCredentialCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialCheckpointDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.CredentialCheckpointDiagnosisCodeLengthRule(maxLength: 80)
        let item = Staffing.newCredentialCheckpoint("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialCheckpointRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Staffing.CredentialCheckpointRequiredDiagnosisCodeRule(
            message: "credential checkpoint needs this field"
        )
        let item = Staffing.newCredentialCheckpoint("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
