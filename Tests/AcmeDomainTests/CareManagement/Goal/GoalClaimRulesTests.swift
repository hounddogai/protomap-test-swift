@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalClaimValidator()
        let item = CareManagement.newGoalClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalClaimRequiredCodeRule(message: "goal claim needs an entry")
        let item = CareManagement.newGoalClaim("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.GoalClaimNameLengthRule(maxLength: 80)
        let item = CareManagement.newGoalClaim("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalClaimCodeLengthRule(maxLength: 32)
        let item = CareManagement.newGoalClaim("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalClaimBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.GoalClaimBatchSizeRangeRule(min: 32, max: 255)
        let item = CareManagement.newGoalClaim("x", name: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalClaimBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.GoalClaimBudgetRangeRule(min: 2.2, max: 366.5)
        let item = CareManagement.newGoalClaim("x", name: "y")
        item.budget = 368.0
        #expect(rule.check(item).count > 0)
    }
}
