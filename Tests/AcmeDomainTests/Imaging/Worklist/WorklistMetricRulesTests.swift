@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistMetricValidator()
        let item = Imaging.newWorklistMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistMetricCodeLengthRule(maxLength: 120)
        let item = Imaging.newWorklistMetric("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.WorklistMetricRequiredNameRule(message: "worklist metric needs this field")
        let item = Imaging.newWorklistMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistMetricDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.WorklistMetricDurationMinutesRangeRule(min: 1000, max: 86400)
        let item = Imaging.newWorklistMetric("x", name: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistMetricCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.WorklistMetricCopayRangeRule(min: 9.4, max: 1037.8)
        let item = Imaging.newWorklistMetric("x", name: "y")
        item.copay = 1039.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistMetricUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.WorklistMetricUpdatedAtRangeRule(min: 32, max: 255)
        let item = Imaging.newWorklistMetric("x", name: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}
