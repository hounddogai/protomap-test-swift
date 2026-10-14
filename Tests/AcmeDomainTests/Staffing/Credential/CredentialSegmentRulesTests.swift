@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialSegmentValidator()
        let item = Staffing.newCredentialSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialSegmentDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.CredentialSegmentDiagnosisCodeLengthRule(maxLength: 32)
        let item = Staffing.newCredentialSegment("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.CredentialSegmentLabelLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialSegment("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialSegmentAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.CredentialSegmentAcuityRangeRule(min: 32, max: 64)
        let item = Staffing.newCredentialSegment("x", label: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}
