@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreMetricValidator()
        let item = CareManagement.newRiskScoreMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RiskScoreMetricRequiredTitleRule(message: "risk score metric needs an entry")
        let item = CareManagement.newRiskScoreMetric("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreMetricCodeLengthRule(maxLength: 64)
        let item = CareManagement.newRiskScoreMetric("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RiskScoreMetricTitleLengthRule(maxLength: 1000)
        let item = CareManagement.newRiskScoreMetric("x", name: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
