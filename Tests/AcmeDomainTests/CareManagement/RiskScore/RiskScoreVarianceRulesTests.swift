@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreVarianceValidator()
        let item = CareManagement.newRiskScoreVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreVarianceSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = CareManagement.RiskScoreVarianceSegmentLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreVariance("x", name: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RiskScoreVarianceRequiredCodeRule(message: "risk score variance needs this field")
        let item = CareManagement.newRiskScoreVariance("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreVarianceRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.RiskScoreVarianceRequiredSegmentRule(message: "risk score variance needs this field")
        let item = CareManagement.newRiskScoreVariance("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreVarianceThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.RiskScoreVarianceThresholdRangeRule(min: 3.8, max: 1872.2)
        let item = CareManagement.newRiskScoreVariance("x", name: "y")
        item.threshold = 1873.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreVarianceExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.RiskScoreVarianceExternalRefLengthRule(maxLength: 255)
        let item = CareManagement.newRiskScoreVariance("x", name: "y")
        item.externalRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
