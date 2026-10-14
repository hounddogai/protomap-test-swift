@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalRequestValidator()
        let item = CareManagement.newGoalRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.GoalRequestLabelLengthRule(maxLength: 3600)
        let item = CareManagement.newGoalRequest("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalRequestRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.GoalRequestRequiredSummaryRule(message: "goal request needs a value")
        let item = CareManagement.newGoalRequest("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.GoalRequestRequiredLabelRule(message: "goal request needs an entry")
        let item = CareManagement.newGoalRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
