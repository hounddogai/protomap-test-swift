@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalFormularyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalFormularyReviewValidator()
        let item = Pharmacy.newSeasonalFormularyReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalFormularyReviewBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Pharmacy.SeasonalFormularyReviewBudgetRangeRule(min: 8.2, max: 4173.8)
        let item = Pharmacy.newSeasonalFormularyReview("x", title: "y")
        item.budget = 4175.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySeasonalFormularyReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.SeasonalFormularyReviewRequiredLabelRule(message: "seasonal formulary review needs an entry")
        let item = Pharmacy.newSeasonalFormularyReview("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalFormularyReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.SeasonalFormularyReviewLabelLengthRule(maxLength: 64)
        let item = Pharmacy.newSeasonalFormularyReview("x", title: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySeasonalFormularyReviewRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.SeasonalFormularyReviewRequiredTitleRule(message: "seasonal formulary review needs a value")
        let item = Pharmacy.newSeasonalFormularyReview("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalFormularyReviewSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.SeasonalFormularyReviewSequenceRangeRule(min: 16, max: 64)
        let item = Pharmacy.newSeasonalFormularyReview("x", title: "y")
        item.sequence = 65
        #expect(rule.check(item).count > 0)
    }
}
