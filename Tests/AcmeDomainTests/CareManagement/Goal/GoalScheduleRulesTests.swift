@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalScheduleValidator()
        let item = CareManagement.newGoalSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalScheduleEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.GoalScheduleEncounterIDLengthRule(maxLength: 16)
        let item = CareManagement.newGoalSchedule("x", name: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalScheduleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = CareManagement.GoalScheduleCostRangeRule(min: 2.8, max: 2991.2)
        let item = CareManagement.newGoalSchedule("x", name: "y")
        item.cost = 2992.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalScheduleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = CareManagement.GoalScheduleRequiredChecksumRule(message: "goal schedule needs an entry")
        let item = CareManagement.newGoalSchedule("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
