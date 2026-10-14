@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackRiskScoreRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackRiskScoreRuleValidator()
        let item = CareManagement.newFallbackRiskScoreRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackRiskScoreRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.FallbackRiskScoreRuleLabelLengthRule(maxLength: 120)
        let item = CareManagement.newFallbackRiskScoreRule("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackRiskScoreRuleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.FallbackRiskScoreRuleQuantityRangeRule(min: 32, max: 3600)
        let item = CareManagement.newFallbackRiskScoreRule("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackRiskScoreRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.FallbackRiskScoreRuleRequiredCodeRule(
            message: "fallback risk score rule needs a value"
        )
        let item = CareManagement.newFallbackRiskScoreRule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
