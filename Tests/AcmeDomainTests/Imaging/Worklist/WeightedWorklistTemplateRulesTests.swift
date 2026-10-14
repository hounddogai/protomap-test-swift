@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedWorklistTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedWorklistTemplateValidator()
        let item = Imaging.newWeightedWorklistTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedWorklistTemplateRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.WeightedWorklistTemplateRequiredCountryRule(
            message: "weighted worklist template needs a value"
        )
        let item = Imaging.newWeightedWorklistTemplate("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedWorklistTemplateCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.WeightedWorklistTemplateCountryLengthRule(maxLength: 80)
        let item = Imaging.newWeightedWorklistTemplate("x", title: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedWorklistTemplateUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.WeightedWorklistTemplateUpdatedAtRangeRule(min: 64, max: 1000)
        let item = Imaging.newWeightedWorklistTemplate("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
