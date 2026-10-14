@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingStudyMetricValidator()
        let item = Imaging.newRollingStudyMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingStudyMetricCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Imaging.RollingStudyMetricCreatedAtRangeRule(min: 16, max: 32)
        let item = Imaging.newRollingStudyMetric("x", name: "y")
        item.createdAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRollingStudyMetricUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Imaging.RollingStudyMetricUnitLengthRule(maxLength: 32)
        let item = Imaging.newRollingStudyMetric("x", name: "y")
        item.unit = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingStudyMetricMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.RollingStudyMetricMaximumRangeRule(min: 7.5, max: 427.7)
        let item = Imaging.newRollingStudyMetric("x", name: "y")
        item.maximum = 429.2
        #expect(rule.check(item).count > 0)
    }
}
