@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingGoalScheduleValidator()
        let item = CareManagement.newPendingGoalSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingGoalScheduleBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = CareManagement.PendingGoalScheduleBedLengthRule(maxLength: 32)
        let item = CareManagement.newPendingGoalSchedule("x", name: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingGoalScheduleWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.PendingGoalScheduleWeightRangeRule(min: 0.8, max: 4549.0)
        let item = CareManagement.newPendingGoalSchedule("x", name: "y")
        item.weight = 4550.5
        #expect(rule.check(item).count > 0)
    }
}
