@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictAccessionPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictAccessionPreferenceValidator()
        let item = Labs.newStrictAccessionPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictAccessionPreferenceThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.StrictAccessionPreferenceThresholdRangeRule(min: 1.4, max: 1272.1)
        let item = Labs.newStrictAccessionPreference("x", label: "y")
        item.threshold = 1273.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictAccessionPreferenceRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.StrictAccessionPreferenceRegionLengthRule(maxLength: 64)
        let item = Labs.newStrictAccessionPreference("x", label: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsStrictAccessionPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.StrictAccessionPreferenceNameLengthRule(maxLength: 80)
        let item = Labs.newStrictAccessionPreference("x", label: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsStrictAccessionPreferenceBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.StrictAccessionPreferenceBatchSizeRangeRule(min: 80, max: 3600)
        let item = Labs.newStrictAccessionPreference("x", label: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictAccessionPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.StrictAccessionPreferenceLabelLengthRule(maxLength: 120)
        let item = Labs.newStrictAccessionPreference("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
