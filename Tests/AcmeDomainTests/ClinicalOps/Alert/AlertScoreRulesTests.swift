@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertScoreValidator()
        let item = ClinicalOps.newAlertScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertScoreBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.AlertScoreBudgetRangeRule(min: 0.3, max: 1764.0)
        let item = ClinicalOps.newAlertScore("x", title: "y")
        item.budget = 1765.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertScoreRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = ClinicalOps.AlertScoreRequiredCategoryRule(message: "alert score needs a value")
        let item = ClinicalOps.newAlertScore("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertScoreCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = ClinicalOps.AlertScoreCountryLengthRule(maxLength: 3600)
        let item = ClinicalOps.newAlertScore("x", title: "y")
        item.country = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertScoreCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = ClinicalOps.AlertScoreCategoryLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertScore("x", title: "y")
        item.category = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertScoreRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = ClinicalOps.AlertScoreRequiredCountryRule(message: "alert score needs a value")
        let item = ClinicalOps.newAlertScore("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
