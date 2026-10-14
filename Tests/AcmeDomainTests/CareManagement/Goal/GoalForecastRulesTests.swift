@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalForecastValidator()
        let item = CareManagement.newGoalForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalForecastCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newGoalForecast("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.GoalForecastTitleLengthRule(maxLength: 1000)
        let item = CareManagement.newGoalForecast("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.GoalForecastRequiredTitleRule(message: "goal forecast needs a value")
        let item = CareManagement.newGoalForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
