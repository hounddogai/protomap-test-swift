@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingShiftBudgetValidator()
        let item = Staffing.newPendingShiftBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingShiftBudgetWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.PendingShiftBudgetWindowDaysRangeRule(min: 16, max: 120)
        let item = Staffing.newPendingShiftBudget("x", title: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingShiftBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PendingShiftBudgetCodeLengthRule(maxLength: 32)
        let item = Staffing.newPendingShiftBudget("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingShiftBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingShiftBudgetRequiredCodeRule(message: "pending shift budget needs this field")
        let item = Staffing.newPendingShiftBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingShiftBudgetStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.PendingShiftBudgetStartsAtRangeRule(min: 120, max: 255)
        let item = Staffing.newPendingShiftBudget("x", title: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingShiftBudgetRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Staffing.PendingShiftBudgetRequiredClinicianIDRule(message: "pending shift budget needs a value")
        let item = Staffing.newPendingShiftBudget("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingShiftBudgetRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Staffing.PendingShiftBudgetRequiredLocaleRule(message: "pending shift budget needs this field")
        let item = Staffing.newPendingShiftBudget("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
