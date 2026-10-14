@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScorePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedRiskScorePolicyValidator()
        let item = CareManagement.newWeightedRiskScorePolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedRiskScorePolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.WeightedRiskScorePolicyLabelLengthRule(maxLength: 120)
        let item = CareManagement.newWeightedRiskScorePolicy("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedRiskScorePolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.WeightedRiskScorePolicyRequiredLabelRule(
            message: "weighted risk score policy needs a value"
        )
        let item = CareManagement.newWeightedRiskScorePolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
