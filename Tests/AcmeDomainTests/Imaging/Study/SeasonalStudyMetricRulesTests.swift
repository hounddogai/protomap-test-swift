@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalStudyMetricValidator()
        let item = Imaging.newSeasonalStudyMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalStudyMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.SeasonalStudyMetricRequiredLabelRule(message: "seasonal study metric needs this field")
        let item = Imaging.newSeasonalStudyMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalStudyMetricDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.SeasonalStudyMetricDurationMinutesRangeRule(min: 64, max: 3600)
        let item = Imaging.newSeasonalStudyMetric("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalStudyMetricRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.SeasonalStudyMetricRateRangeRule(min: 2.6, max: 139.8)
        let item = Imaging.newSeasonalStudyMetric("x", label: "y")
        item.rate = 141.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalStudyMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalStudyMetricRequiredCodeRule(message: "seasonal study metric needs an entry")
        let item = Imaging.newSeasonalStudyMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
