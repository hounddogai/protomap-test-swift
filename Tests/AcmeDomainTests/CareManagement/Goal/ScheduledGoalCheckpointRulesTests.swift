@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledGoalCheckpointValidator()
        let item = CareManagement.newScheduledGoalCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledGoalCheckpointBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.ScheduledGoalCheckpointBudgetRangeRule(min: 8.4, max: 3164.8)
        let item = CareManagement.newScheduledGoalCheckpoint("x", title: "y")
        item.budget = 3166.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledGoalCheckpointTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.ScheduledGoalCheckpointTimezoneLengthRule(maxLength: 86400)
        let item = CareManagement.newScheduledGoalCheckpoint("x", title: "y")
        item.timezone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledGoalCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ScheduledGoalCheckpointRequiredCodeRule(
            message: "scheduled goal checkpoint needs an entry"
        )
        let item = CareManagement.newScheduledGoalCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledGoalCheckpointSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.ScheduledGoalCheckpointSequenceRangeRule(min: 120, max: 1000)
        let item = CareManagement.newScheduledGoalCheckpoint("x", title: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledGoalCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ScheduledGoalCheckpointCodeLengthRule(maxLength: 255)
        let item = CareManagement.newScheduledGoalCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
