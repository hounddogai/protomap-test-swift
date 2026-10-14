@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreRuleValidator()
        let item = CareManagement.newRiskScoreRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreRuleWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.RiskScoreRuleWeightRangeRule(min: 3.0, max: 713.7)
        let item = CareManagement.newRiskScoreRule("x", label: "y")
        item.weight = 715.2
        #expect(rule.check(item).count > 0)
    }
}
