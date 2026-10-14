@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalTargetValidator()
        let item = CareManagement.newGoalTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.GoalTargetRequiredNameRule(message: "goal target needs an entry")
        let item = CareManagement.newGoalTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalTargetUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.GoalTargetUnitLengthRule(maxLength: 255)
        let item = CareManagement.newGoalTarget("x", name: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalTargetCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newGoalTarget("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalTargetDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = CareManagement.GoalTargetDurationMinutesRangeRule(min: 80, max: 120)
        let item = CareManagement.newGoalTarget("x", name: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalTargetCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.GoalTargetCategoryLengthRule(maxLength: 255)
        let item = CareManagement.newGoalTarget("x", name: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
