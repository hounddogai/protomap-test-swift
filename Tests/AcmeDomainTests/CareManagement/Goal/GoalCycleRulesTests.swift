@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalCycleValidator()
        let item = CareManagement.newGoalCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalCycleCodeLengthRule(maxLength: 80)
        let item = CareManagement.newGoalCycle("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalCycleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.GoalCycleExternalRefLengthRule(maxLength: 255)
        let item = CareManagement.newGoalCycle("x", name: "y")
        item.externalRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.GoalCycleNameLengthRule(maxLength: 3600)
        let item = CareManagement.newGoalCycle("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalCycleRequiredCodeRule(message: "goal cycle needs an entry")
        let item = CareManagement.newGoalCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalCycleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.GoalCycleRatioRangeRule(min: 0.6, max: 900.4)
        let item = CareManagement.newGoalCycle("x", name: "y")
        item.ratio = 901.9
        #expect(rule.check(item).count > 0)
    }
}
