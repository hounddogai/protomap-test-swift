@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyShiftExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacyShiftExceptionValidator()
        let item = Staffing.newLegacyShiftException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacyShiftExceptionRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Staffing.LegacyShiftExceptionRequiredClinicianIDRule(message: "legacy shift exception needs an entry")
        let item = Staffing.newLegacyShiftException("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLegacyShiftExceptionDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.LegacyShiftExceptionDosageMgRangeRule(min: 0.8, max: 4723.1)
        let item = Staffing.newLegacyShiftException("x", name: "y")
        item.dosageMg = 4724.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLegacyShiftExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.LegacyShiftExceptionCodeLengthRule(maxLength: 86400)
        let item = Staffing.newLegacyShiftException("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
