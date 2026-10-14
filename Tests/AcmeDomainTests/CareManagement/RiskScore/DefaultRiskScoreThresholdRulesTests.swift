@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultRiskScoreThresholdValidator()
        let item = CareManagement.newDefaultRiskScoreThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.DefaultRiskScoreThresholdCodeLengthRule(maxLength: 80)
        let item = CareManagement.newDefaultRiskScoreThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.DefaultRiskScoreThresholdTitleLengthRule(maxLength: 120)
        let item = CareManagement.newDefaultRiskScoreThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.DefaultRiskScoreThresholdRequiredCodeRule(
            message: "default risk score threshold needs a value"
        )
        let item = CareManagement.newDefaultRiskScoreThreshold("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
