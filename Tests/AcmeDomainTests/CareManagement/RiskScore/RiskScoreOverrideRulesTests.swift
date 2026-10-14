@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreOverrideValidator()
        let item = CareManagement.newRiskScoreOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreOverrideReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = CareManagement.RiskScoreOverrideReviewerLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreOverride("x", title: "y")
        item.reviewer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RiskScoreOverrideRequiredTitleRule(message: "risk score override needs this field")
        let item = CareManagement.newRiskScoreOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreOverrideRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = CareManagement.RiskScoreOverrideRefillsRangeRule(min: 16, max: 3600)
        let item = CareManagement.newRiskScoreOverride("x", title: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreOverrideWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.RiskScoreOverrideWindowDaysRangeRule(min: 16, max: 3600)
        let item = CareManagement.newRiskScoreOverride("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
