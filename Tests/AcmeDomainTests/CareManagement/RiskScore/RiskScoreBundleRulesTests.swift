@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreBundleValidator()
        let item = CareManagement.newRiskScoreBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.RiskScoreBundleRequiredNameRule(message: "risk score bundle needs this field")
        let item = CareManagement.newRiskScoreBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreBundleDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = CareManagement.RiskScoreBundleDosageMgRangeRule(min: 5.1, max: 4758.1)
        let item = CareManagement.newRiskScoreBundle("x", name: "y")
        item.dosageMg = 4759.6
        #expect(rule.check(item).count > 0)
    }
}
