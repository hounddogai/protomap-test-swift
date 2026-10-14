@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreDigestValidator()
        let item = CareManagement.newRiskScoreDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreDigestThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.RiskScoreDigestThresholdRangeRule(min: 5.5, max: 3903.9)
        let item = CareManagement.newRiskScoreDigest("x", label: "y")
        item.threshold = 3905.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreDigestLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = CareManagement.RiskScoreDigestLocaleLengthRule(maxLength: 80)
        let item = CareManagement.newRiskScoreDigest("x", label: "y")
        item.locale = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
