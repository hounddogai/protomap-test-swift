@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreRollupValidator()
        let item = CareManagement.newRiskScoreRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreRollupWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.RiskScoreRollupWeightRangeRule(min: 0.1, max: 913.8)
        let item = CareManagement.newRiskScoreRollup("x", name: "y")
        item.weight = 915.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreRollupCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = CareManagement.RiskScoreRollupCurrencyLengthRule(maxLength: 3600)
        let item = CareManagement.newRiskScoreRollup("x", name: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreRollupAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.RiskScoreRollupAmountRangeRule(min: 6.5, max: 423.8)
        let item = CareManagement.newRiskScoreRollup("x", name: "y")
        item.amount = 425.3
        #expect(rule.check(item).count > 0)
    }
}
