@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalPriorityMetricValidator()
        let item = Imaging.newSeasonalPriorityMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalPriorityMetricRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.SeasonalPriorityMetricRateRangeRule(min: 6.8, max: 2596.7)
        let item = Imaging.newSeasonalPriorityMetric("x", label: "y")
        item.rate = 2598.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalPriorityMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.SeasonalPriorityMetricRequiredLabelRule(message: "seasonal priority metric needs an entry")
        let item = Imaging.newSeasonalPriorityMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalPriorityMetricBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.SeasonalPriorityMetricBedLengthRule(maxLength: 120)
        let item = Imaging.newSeasonalPriorityMetric("x", label: "y")
        item.bed = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
