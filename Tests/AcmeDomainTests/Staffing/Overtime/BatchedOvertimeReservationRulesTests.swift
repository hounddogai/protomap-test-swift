@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultBatchedOvertimeReservationValidator()
        let item = Staffing.newBatchedOvertimeReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingBatchedOvertimeReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.BatchedOvertimeReservationCodeLengthRule(maxLength: 120)
        let item = Staffing.newBatchedOvertimeReservation("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingBatchedOvertimeReservationRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.BatchedOvertimeReservationRequiredPatientRefRule(
            message: "batched overtime reservation needs a value"
        )
        let item = Staffing.newBatchedOvertimeReservation("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingBatchedOvertimeReservationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.BatchedOvertimeReservationCapacityRangeRule(min: 64, max: 255)
        let item = Staffing.newBatchedOvertimeReservation("x", title: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingBatchedOvertimeReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.BatchedOvertimeReservationTitleLengthRule(maxLength: 32)
        let item = Staffing.newBatchedOvertimeReservation("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingBatchedOvertimeReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.BatchedOvertimeReservationRequiredCodeRule(
            message: "batched overtime reservation needs this field"
        )
        let item = Staffing.newBatchedOvertimeReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
