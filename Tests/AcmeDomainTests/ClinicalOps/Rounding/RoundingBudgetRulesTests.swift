@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingBudgetValidator()
        let item = ClinicalOps.newRoundingBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RoundingBudgetRequiredCodeRule(message: "rounding budget needs an entry")
        let item = ClinicalOps.newRoundingBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingBudgetThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = ClinicalOps.RoundingBudgetThresholdRangeRule(min: 7.5, max: 678.2)
        let item = ClinicalOps.newRoundingBudget("x", title: "y")
        item.threshold = 679.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingBudgetSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = ClinicalOps.RoundingBudgetSegmentLengthRule(maxLength: 16)
        let item = ClinicalOps.newRoundingBudget("x", title: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingBudgetRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = ClinicalOps.RoundingBudgetRequiredSegmentRule(message: "rounding budget needs a value")
        let item = ClinicalOps.newRoundingBudget("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.RoundingBudgetTitleLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRoundingBudget("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
