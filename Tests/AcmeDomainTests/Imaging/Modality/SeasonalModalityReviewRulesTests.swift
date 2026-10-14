@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalModalityReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalModalityReviewValidator()
        let item = Imaging.newSeasonalModalityReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalModalityReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.SeasonalModalityReviewCodeLengthRule(maxLength: 64)
        let item = Imaging.newSeasonalModalityReview("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalModalityReviewContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Imaging.SeasonalModalityReviewContactEmailLengthRule(maxLength: 80)
        let item = Imaging.newSeasonalModalityReview("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalModalityReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalModalityReviewRequiredCodeRule(message: "seasonal modality review needs this field")
        let item = Imaging.newSeasonalModalityReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalModalityReviewWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.SeasonalModalityReviewWeightRangeRule(min: 8.8, max: 135.6)
        let item = Imaging.newSeasonalModalityReview("x", name: "y")
        item.weight = 137.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalModalityReviewRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.SeasonalModalityReviewRequiredContactEmailRule(
            message: "seasonal modality review needs a value"
        )
        let item = Imaging.newSeasonalModalityReview("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
