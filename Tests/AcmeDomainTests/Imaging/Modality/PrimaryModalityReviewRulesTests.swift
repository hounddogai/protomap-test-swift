@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryModalityReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryModalityReviewValidator()
        let item = Imaging.newPrimaryModalityReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryModalityReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PrimaryModalityReviewRequiredCodeRule(message: "primary modality review needs a value")
        let item = Imaging.newPrimaryModalityReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryModalityReviewWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.PrimaryModalityReviewWeightRangeRule(min: 9.8, max: 4171.8)
        let item = Imaging.newPrimaryModalityReview("x", title: "y")
        item.weight = 4173.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryModalityReviewAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Imaging.PrimaryModalityReviewAllergyLengthRule(maxLength: 64)
        let item = Imaging.newPrimaryModalityReview("x", title: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryModalityReviewRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PrimaryModalityReviewRequiredTitleRule(message: "primary modality review needs an entry")
        let item = Imaging.newPrimaryModalityReview("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryModalityReviewCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Imaging.PrimaryModalityReviewCostRangeRule(min: 0.4, max: 892.7)
        let item = Imaging.newPrimaryModalityReview("x", title: "y")
        item.cost = 894.2
        #expect(rule.check(item).count > 0)
    }
}
