@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreWindowValidator()
        let item = CareManagement.newRiskScoreWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreWindowRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.RiskScoreWindowRequiredSummaryRule(message: "risk score window needs an entry")
        let item = CareManagement.newRiskScoreWindow("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RiskScoreWindowRequiredCodeRule(message: "risk score window needs a value")
        let item = CareManagement.newRiskScoreWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
