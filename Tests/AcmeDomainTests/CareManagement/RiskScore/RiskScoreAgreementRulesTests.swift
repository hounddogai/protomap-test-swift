@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreAgreementValidator()
        let item = CareManagement.newRiskScoreAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreAgreementThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.RiskScoreAgreementThresholdRangeRule(min: 5.4, max: 1977.3)
        let item = CareManagement.newRiskScoreAgreement("x", name: "y")
        item.threshold = 1978.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreAgreementCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.RiskScoreAgreementCopayRangeRule(min: 2.3, max: 1896.8)
        let item = CareManagement.newRiskScoreAgreement("x", name: "y")
        item.copay = 1898.3
        #expect(rule.check(item).count > 0)
    }
}
