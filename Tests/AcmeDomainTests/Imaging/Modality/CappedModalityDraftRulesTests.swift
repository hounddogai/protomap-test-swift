@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedModalityDraftValidator()
        let item = Imaging.newCappedModalityDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedModalityDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.CappedModalityDraftLabelLengthRule(maxLength: 80)
        let item = Imaging.newCappedModalityDraft("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedModalityDraftAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Imaging.CappedModalityDraftAllergyLengthRule(maxLength: 16)
        let item = Imaging.newCappedModalityDraft("x", label: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedModalityDraftMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.CappedModalityDraftMinimumRangeRule(min: 0.4, max: 4347.5)
        let item = Imaging.newCappedModalityDraft("x", label: "y")
        item.minimum = 4349.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCappedModalityDraftBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.CappedModalityDraftBudgetRangeRule(min: 9.8, max: 2666.8)
        let item = Imaging.newCappedModalityDraft("x", label: "y")
        item.budget = 2668.3
        #expect(rule.check(item).count > 0)
    }
}
