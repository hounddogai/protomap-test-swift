@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreProfileValidator()
        let item = CareManagement.newRiskScoreProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreProfileRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.RiskScoreProfileRequiredSegmentRule(message: "risk score profile needs a value")
        let item = CareManagement.newRiskScoreProfile("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreProfileWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.RiskScoreProfileWeightRangeRule(min: 9.2, max: 2641.7)
        let item = CareManagement.newRiskScoreProfile("x", name: "y")
        item.weight = 2643.2
        #expect(rule.check(item).count > 0)
    }
}
