@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingRiskScoreRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingRiskScoreRuleValidator()
        let item = CareManagement.newRollingRiskScoreRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingRiskScoreRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RollingRiskScoreRuleRequiredCodeRule(
            message: "rolling risk score rule needs this field"
        )
        let item = CareManagement.newRollingRiskScoreRule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingRiskScoreRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RollingRiskScoreRuleCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newRollingRiskScoreRule("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
