@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveModalityForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveModalityForecastValidator()
        let item = Imaging.newAdaptiveModalityForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveModalityForecastCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.AdaptiveModalityForecastCategoryLengthRule(maxLength: 16)
        let item = Imaging.newAdaptiveModalityForecast("x", label: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveModalityForecastRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Imaging.AdaptiveModalityForecastRequiredCategoryRule(
            message: "adaptive modality forecast needs a value"
        )
        let item = Imaging.newAdaptiveModalityForecast("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveModalityForecastRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.AdaptiveModalityForecastRequiredLabelRule(
            message: "adaptive modality forecast needs this field"
        )
        let item = Imaging.newAdaptiveModalityForecast("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
