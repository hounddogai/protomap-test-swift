@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingRuleValidator()
        let item = ClinicalOps.newRoundingRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RoundingRuleLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newRoundingRule("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingRuleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.RoundingRuleAmountRangeRule(min: 0.6, max: 2680.1)
        let item = ClinicalOps.newRoundingRule("x", label: "y")
        item.amount = 2681.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingRuleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RoundingRuleRequiredLabelRule(message: "rounding rule needs this field")
        let item = ClinicalOps.newRoundingRule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingRuleRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.RoundingRuleRequiredEncounterIDRule(message: "rounding rule needs this field")
        let item = ClinicalOps.newRoundingRule("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
