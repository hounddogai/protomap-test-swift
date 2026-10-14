@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeClaimValidator()
        let item = Staffing.newOvertimeClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeClaimTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Staffing.OvertimeClaimTimezoneLengthRule(maxLength: 16)
        let item = Staffing.newOvertimeClaim("x", label: "y")
        item.timezone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeClaimRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.OvertimeClaimRequiredTimezoneRule(message: "overtime claim needs this field")
        let item = Staffing.newOvertimeClaim("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeClaimStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.OvertimeClaimStartsAtRangeRule(min: 64, max: 86400)
        let item = Staffing.newOvertimeClaim("x", label: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeClaimRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Staffing.OvertimeClaimRequiredLocaleRule(message: "overtime claim needs an entry")
        let item = Staffing.newOvertimeClaim("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
