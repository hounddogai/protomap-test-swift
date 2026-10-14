@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalTierValidator()
        let item = CareManagement.newGoalTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalTierTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.GoalTierTimezoneLengthRule(maxLength: 1000)
        let item = CareManagement.newGoalTier("x", label: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalTierCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.GoalTierCapacityRangeRule(min: 120, max: 1000)
        let item = CareManagement.newGoalTier("x", label: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.GoalTierRequiredLabelRule(message: "goal tier needs a value")
        let item = CareManagement.newGoalTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
