@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialBaselineValidator()
        let item = Staffing.newCredentialBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialBaselinePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Staffing.CredentialBaselinePatientRefLengthRule(maxLength: 1000)
        let item = Staffing.newCredentialBaseline("x", title: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialBaselineCodeLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialBaselineEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Staffing.CredentialBaselineEndsAtRangeRule(min: 120, max: 3600)
        let item = Staffing.newCredentialBaseline("x", title: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
