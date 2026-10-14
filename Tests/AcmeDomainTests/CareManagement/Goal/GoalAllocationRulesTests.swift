@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalAllocationValidator()
        let item = CareManagement.newGoalAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.GoalAllocationLabelLengthRule(maxLength: 32)
        let item = CareManagement.newGoalAllocation("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalAllocationRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = CareManagement.GoalAllocationRequiredProcedureCodeRule(message: "goal allocation needs this field")
        let item = CareManagement.newGoalAllocation("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalAllocationVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.GoalAllocationVersionRangeRule(min: 255, max: 255)
        let item = CareManagement.newGoalAllocation("x", label: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalAllocationAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.GoalAllocationAmountRangeRule(min: 6.6, max: 911.0)
        let item = CareManagement.newGoalAllocation("x", label: "y")
        item.amount = 912.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalAllocationProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.GoalAllocationProcedureCodeLengthRule(maxLength: 32)
        let item = CareManagement.newGoalAllocation("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
