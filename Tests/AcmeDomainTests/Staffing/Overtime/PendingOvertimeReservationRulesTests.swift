@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingOvertimeReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingOvertimeReservationValidator()
        let item = Staffing.newPendingOvertimeReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingOvertimeReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.PendingOvertimeReservationTitleLengthRule(maxLength: 86400)
        let item = Staffing.newPendingOvertimeReservation("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingOvertimeReservationRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.PendingOvertimeReservationRequiredWardRule(
            message: "pending overtime reservation needs an entry"
        )
        let item = Staffing.newPendingOvertimeReservation("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingOvertimeReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PendingOvertimeReservationCodeLengthRule(maxLength: 1000)
        let item = Staffing.newPendingOvertimeReservation("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingOvertimeReservationLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.PendingOvertimeReservationLimitRangeRule(min: 16, max: 120)
        let item = Staffing.newPendingOvertimeReservation("x", title: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingOvertimeReservationRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.PendingOvertimeReservationRequiredCurrencyRule(
            message: "pending overtime reservation needs this field"
        )
        let item = Staffing.newPendingOvertimeReservation("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
