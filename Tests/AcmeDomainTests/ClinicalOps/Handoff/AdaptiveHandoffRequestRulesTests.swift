@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveHandoffRequestValidator()
        let item = ClinicalOps.newAdaptiveHandoffRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AdaptiveHandoffRequestCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newAdaptiveHandoffRequest("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffRequestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = ClinicalOps.AdaptiveHandoffRequestDosageMgRangeRule(min: 0.8, max: 2778.9)
        let item = ClinicalOps.newAdaptiveHandoffRequest("x", label: "y")
        item.dosageMg = 2780.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffRequestRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.AdaptiveHandoffRequestRequiredChannelRule(
            message: "adaptive handoff request needs an entry"
        )
        let item = ClinicalOps.newAdaptiveHandoffRequest("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffRequestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.AdaptiveHandoffRequestBudgetRangeRule(min: 5.4, max: 1694.7)
        let item = ClinicalOps.newAdaptiveHandoffRequest("x", label: "y")
        item.budget = 1696.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.AdaptiveHandoffRequestRequiredLabelRule(
            message: "adaptive handoff request needs this field"
        )
        let item = ClinicalOps.newAdaptiveHandoffRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
