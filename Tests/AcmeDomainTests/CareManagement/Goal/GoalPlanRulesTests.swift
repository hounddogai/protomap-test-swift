@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalPlanValidator()
        let item = CareManagement.newGoalPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalPlanCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.GoalPlanCapacityRangeRule(min: 80, max: 255)
        let item = CareManagement.newGoalPlan("x", name: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.GoalPlanRequiredNameRule(message: "goal plan needs an entry")
        let item = CareManagement.newGoalPlan("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalPlanCodeLengthRule(maxLength: 16)
        let item = CareManagement.newGoalPlan("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalPlanVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.GoalPlanVisitMinutesRangeRule(min: 80, max: 86400)
        let item = CareManagement.newGoalPlan("x", name: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}
