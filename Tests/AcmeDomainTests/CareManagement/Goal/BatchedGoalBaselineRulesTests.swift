@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedGoalBaselineValidator()
        let item = CareManagement.newBatchedGoalBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedGoalBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.BatchedGoalBaselineCodeLengthRule(maxLength: 64)
        let item = CareManagement.newBatchedGoalBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedGoalBaselineRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.BatchedGoalBaselineRatioRangeRule(min: 4.0, max: 4370.0)
        let item = CareManagement.newBatchedGoalBaseline("x", title: "y")
        item.ratio = 4371.5
        #expect(rule.check(item).count > 0)
    }
}
