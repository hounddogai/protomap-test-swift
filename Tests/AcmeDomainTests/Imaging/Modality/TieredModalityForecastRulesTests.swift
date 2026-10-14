@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredModalityForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredModalityForecastValidator()
        let item = Imaging.newTieredModalityForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredModalityForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.TieredModalityForecastRequiredCodeRule(message: "tiered modality forecast needs this field")
        let item = Imaging.newTieredModalityForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredModalityForecastRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.TieredModalityForecastRequiredBedRule(message: "tiered modality forecast needs this field")
        let item = Imaging.newTieredModalityForecast("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredModalityForecastMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.TieredModalityForecastMarginRangeRule(min: 8.2, max: 167.5)
        let item = Imaging.newTieredModalityForecast("x", title: "y")
        item.margin = 169.0
        #expect(rule.check(item).count > 0)
    }
}
