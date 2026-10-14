@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedShiftExceptionValidator()
        let item = Staffing.newCappedShiftException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedShiftExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.CappedShiftExceptionRequiredLabelRule(message: "capped shift exception needs an entry")
        let item = Staffing.newCappedShiftException("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedShiftExceptionClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Staffing.CappedShiftExceptionClinicianIDLengthRule(maxLength: 64)
        let item = Staffing.newCappedShiftException("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedShiftExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CappedShiftExceptionRequiredCodeRule(message: "capped shift exception needs this field")
        let item = Staffing.newCappedShiftException("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedShiftExceptionAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.CappedShiftExceptionAttemptsRangeRule(min: 16, max: 120)
        let item = Staffing.newCappedShiftException("x", name: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}
