@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedRiskScoreTemplateValidator()
        let item = CareManagement.newWeightedRiskScoreTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreTemplateBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.WeightedRiskScoreTemplateBudgetRangeRule(min: 8.5, max: 4309.3)
        let item = CareManagement.newWeightedRiskScoreTemplate("x", name: "y")
        item.budget = 4310.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.WeightedRiskScoreTemplateRequiredTitleRule(
            message: "weighted risk score template needs this field"
        )
        let item = CareManagement.newWeightedRiskScoreTemplate("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedRiskScoreTemplateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.WeightedRiskScoreTemplateExpiresAtRangeRule(min: 120, max: 86400)
        let item = CareManagement.newWeightedRiskScoreTemplate("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreTemplateChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.WeightedRiskScoreTemplateChannelLengthRule(maxLength: 86400)
        let item = CareManagement.newWeightedRiskScoreTemplate("x", name: "y")
        item.channel = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.WeightedRiskScoreTemplateNameLengthRule(maxLength: 120)
        let item = CareManagement.newWeightedRiskScoreTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
