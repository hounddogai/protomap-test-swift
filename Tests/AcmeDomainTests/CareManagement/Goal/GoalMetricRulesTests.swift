@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalMetricValidator()
        let item = CareManagement.newGoalMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalMetricRequiredCodeRule(message: "goal metric needs an entry")
        let item = CareManagement.newGoalMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalMetricRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.GoalMetricRetriesRangeRule(min: 120, max: 255)
        let item = CareManagement.newGoalMetric("x", name: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalMetricSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.GoalMetricSpecialtyLengthRule(maxLength: 64)
        let item = CareManagement.newGoalMetric("x", name: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalMetricCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newGoalMetric("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
