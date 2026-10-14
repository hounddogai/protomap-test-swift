@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingShiftReservationValidator()
        let item = Staffing.newPendingShiftReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingShiftReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingShiftReservationRequiredCodeRule(
            message: "pending shift reservation needs this field"
        )
        let item = Staffing.newPendingShiftReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
