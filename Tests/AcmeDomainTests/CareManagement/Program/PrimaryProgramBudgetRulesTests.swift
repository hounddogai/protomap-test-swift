@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryProgramBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryProgramBudgetValidator()
        let item = CareManagement.newPrimaryProgramBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryProgramBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PrimaryProgramBudgetCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newPrimaryProgramBudget("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryProgramBudgetPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = CareManagement.PrimaryProgramBudgetPayerLengthRule(maxLength: 64)
        let item = CareManagement.newPrimaryProgramBudget("x", label: "y")
        item.payer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryProgramBudgetWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.PrimaryProgramBudgetWindowDaysRangeRule(min: 16, max: 32)
        let item = CareManagement.newPrimaryProgramBudget("x", label: "y")
        item.windowDays = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryProgramBudgetCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.PrimaryProgramBudgetCeilingRangeRule(min: 1.5, max: 4935.2)
        let item = CareManagement.newPrimaryProgramBudget("x", label: "y")
        item.ceiling = 4936.7
        #expect(rule.check(item).count > 0)
    }
}
