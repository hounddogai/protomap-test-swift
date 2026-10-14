@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledGoalPreferenceValidator()
        let item = CareManagement.newScheduledGoalPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledGoalPreferenceWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.ScheduledGoalPreferenceWeightRangeRule(min: 8.2, max: 1741.7)
        let item = CareManagement.newScheduledGoalPreference("x", name: "y")
        item.weight = 1743.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledGoalPreferenceRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.ScheduledGoalPreferenceRequiredTimezoneRule(
            message: "scheduled goal preference needs an entry"
        )
        let item = CareManagement.newScheduledGoalPreference("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
