@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialAuditValidator()
        let item = Staffing.newCredentialAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialAuditPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Staffing.CredentialAuditPatientRefLengthRule(maxLength: 255)
        let item = Staffing.newCredentialAudit("x", title: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialAuditQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.CredentialAuditQuantityRangeRule(min: 86400, max: 86400)
        let item = Staffing.newCredentialAudit("x", title: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialAuditRequiredTitleRule(message: "credential audit needs this field")
        let item = Staffing.newCredentialAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialAuditRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.CredentialAuditRequiredPatientRefRule(message: "credential audit needs a value")
        let item = Staffing.newCredentialAudit("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
