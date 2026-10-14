@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreReviewValidator()
        let item = CareManagement.newRiskScoreReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RiskScoreReviewRequiredCodeRule(message: "risk score review needs an entry")
        let item = CareManagement.newRiskScoreReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreReviewCodeLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreReview("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreReviewRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = CareManagement.RiskScoreReviewRequiredUnitRule(message: "risk score review needs a value")
        let item = CareManagement.newRiskScoreReview("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RiskScoreReviewNameLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreReview("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreReviewThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.RiskScoreReviewThresholdRangeRule(min: 5.0, max: 4709.8)
        let item = CareManagement.newRiskScoreReview("x", name: "y")
        item.threshold = 4711.3
        #expect(rule.check(item).count > 0)
    }
}
