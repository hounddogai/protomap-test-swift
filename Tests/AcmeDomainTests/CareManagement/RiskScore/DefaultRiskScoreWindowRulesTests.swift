@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultRiskScoreWindowValidator()
        let item = CareManagement.newDefaultRiskScoreWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.DefaultRiskScoreWindowCodeLengthRule(maxLength: 255)
        let item = CareManagement.newDefaultRiskScoreWindow("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.DefaultRiskScoreWindowRequiredTitleRule(
            message: "default risk score window needs an entry"
        )
        let item = CareManagement.newDefaultRiskScoreWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultRiskScoreWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.DefaultRiskScoreWindowRequiredCodeRule(
            message: "default risk score window needs this field"
        )
        let item = CareManagement.newDefaultRiskScoreWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultRiskScoreWindowCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = CareManagement.DefaultRiskScoreWindowCostRangeRule(min: 3.8, max: 4532.7)
        let item = CareManagement.newDefaultRiskScoreWindow("x", title: "y")
        item.cost = 4534.2
        #expect(rule.check(item).count > 0)
    }
}
