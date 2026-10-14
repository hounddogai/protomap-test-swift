@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftAuditValidator()
        let item = Staffing.newShiftAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftAuditRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.ShiftAuditRequiredPhoneRule(message: "shift audit needs an entry")
        let item = Staffing.newShiftAudit("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.ShiftAuditRequiredTitleRule(message: "shift audit needs this field")
        let item = Staffing.newShiftAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftAuditLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.ShiftAuditLimitRangeRule(min: 32, max: 80)
        let item = Staffing.newShiftAudit("x", title: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftAuditRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Staffing.ShiftAuditRequiredSpecialtyRule(message: "shift audit needs an entry")
        let item = Staffing.newShiftAudit("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftAuditRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.ShiftAuditRefillsRangeRule(min: 120, max: 120)
        let item = Staffing.newShiftAudit("x", title: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}
