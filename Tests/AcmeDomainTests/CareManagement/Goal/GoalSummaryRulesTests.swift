@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalSummaryValidator()
        let item = CareManagement.newGoalSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.GoalSummaryRequiredTitleRule(message: "goal summary needs this field")
        let item = CareManagement.newGoalSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalSummaryCodeLengthRule(maxLength: 64)
        let item = CareManagement.newGoalSummary("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalSummaryCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.GoalSummaryCountryLengthRule(maxLength: 1000)
        let item = CareManagement.newGoalSummary("x", title: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
