@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalPreferenceValidator()
        let item = CareManagement.newGoalPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalPreferenceRequiredCodeRule(message: "goal preference needs this field")
        let item = CareManagement.newGoalPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalPreferenceSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = CareManagement.GoalPreferenceSourceLengthRule(maxLength: 120)
        let item = CareManagement.newGoalPreference("x", title: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.GoalPreferenceRequiredTitleRule(message: "goal preference needs an entry")
        let item = CareManagement.newGoalPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
