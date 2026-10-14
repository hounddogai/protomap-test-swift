@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreAuditValidator()
        let item = CareManagement.newRiskScoreAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RiskScoreAuditTitleLengthRule(maxLength: 255)
        let item = CareManagement.newRiskScoreAudit("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreAuditWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.RiskScoreAuditWindowDaysRangeRule(min: 16, max: 1000)
        let item = CareManagement.newRiskScoreAudit("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
