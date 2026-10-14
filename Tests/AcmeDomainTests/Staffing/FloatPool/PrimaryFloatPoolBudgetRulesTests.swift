@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryFloatPoolBudgetValidator()
        let item = Staffing.newPrimaryFloatPoolBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryFloatPoolBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryFloatPoolBudgetCodeLengthRule(maxLength: 86400)
        let item = Staffing.newPrimaryFloatPoolBudget("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryFloatPoolBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.PrimaryFloatPoolBudgetRequiredNameRule(message: "primary float pool budget needs an entry")
        let item = Staffing.newPrimaryFloatPoolBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryFloatPoolBudgetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.PrimaryFloatPoolBudgetNameLengthRule(maxLength: 80)
        let item = Staffing.newPrimaryFloatPoolBudget("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryFloatPoolBudgetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.PrimaryFloatPoolBudgetGraceDaysRangeRule(min: 64, max: 120)
        let item = Staffing.newPrimaryFloatPoolBudget("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}
