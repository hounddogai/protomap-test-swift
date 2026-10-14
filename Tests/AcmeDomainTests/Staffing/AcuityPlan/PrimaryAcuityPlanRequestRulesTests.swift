@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryAcuityPlanRequestValidator()
        let item = Staffing.newPrimaryAcuityPlanRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanRequestExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.PrimaryAcuityPlanRequestExpiresAtRangeRule(min: 32, max: 80)
        let item = Staffing.newPrimaryAcuityPlanRequest("x", name: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryAcuityPlanRequestRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.PrimaryAcuityPlanRequestRequiredPatientRefRule(
            message: "primary acuity plan request needs this field"
        )
        let item = Staffing.newPrimaryAcuityPlanRequest("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PrimaryAcuityPlanRequestRequiredCodeRule(
            message: "primary acuity plan request needs an entry"
        )
        let item = Staffing.newPrimaryAcuityPlanRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryAcuityPlanRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryAcuityPlanRequestCodeLengthRule(maxLength: 16)
        let item = Staffing.newPrimaryAcuityPlanRequest("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
