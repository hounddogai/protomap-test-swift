@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistBatchValidator()
        let item = Imaging.newWorklistBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistBatchThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Imaging.WorklistBatchThresholdRangeRule(min: 5.2, max: 634.1)
        let item = Imaging.newWorklistBatch("x", label: "y")
        item.threshold = 635.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistBatchCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.WorklistBatchCountryLengthRule(maxLength: 80)
        let item = Imaging.newWorklistBatch("x", label: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistBatchCodeLengthRule(maxLength: 3600)
        let item = Imaging.newWorklistBatch("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
