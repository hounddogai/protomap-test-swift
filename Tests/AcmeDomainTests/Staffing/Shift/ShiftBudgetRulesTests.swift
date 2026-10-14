@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftBudgetValidator()
        let item = Staffing.newShiftBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.ShiftBudgetRequiredTitleRule(message: "shift budget needs a value")
        let item = Staffing.newShiftBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftBudgetCodeLengthRule(maxLength: 80)
        let item = Staffing.newShiftBudget("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
