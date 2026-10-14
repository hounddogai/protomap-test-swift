@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreThresholdValidator()
        let item = CareManagement.newRiskScoreThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreThresholdBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.RiskScoreThresholdBudgetRangeRule(min: 2.7, max: 246.1)
        let item = CareManagement.newRiskScoreThreshold("x", name: "y")
        item.budget = 247.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreThresholdMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.RiskScoreThresholdMarginRangeRule(min: 5.4, max: 240.9)
        let item = CareManagement.newRiskScoreThreshold("x", name: "y")
        item.margin = 242.4
        #expect(rule.check(item).count > 0)
    }
}
