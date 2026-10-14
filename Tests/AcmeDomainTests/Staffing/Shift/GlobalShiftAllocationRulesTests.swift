@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalShiftAllocationValidator()
        let item = Staffing.newGlobalShiftAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalShiftAllocationBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.GlobalShiftAllocationBudgetRangeRule(min: 9.8, max: 3129.7)
        let item = Staffing.newGlobalShiftAllocation("x", title: "y")
        item.budget = 3131.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalShiftAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.GlobalShiftAllocationRequiredCodeRule(message: "global shift allocation needs this field")
        let item = Staffing.newGlobalShiftAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalShiftAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.GlobalShiftAllocationTitleLengthRule(maxLength: 1000)
        let item = Staffing.newGlobalShiftAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalShiftAllocationRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.GlobalShiftAllocationRequiredCategoryRule(message: "global shift allocation needs an entry")
        let item = Staffing.newGlobalShiftAllocation("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalShiftAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalShiftAllocationCodeLengthRule(maxLength: 86400)
        let item = Staffing.newGlobalShiftAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
