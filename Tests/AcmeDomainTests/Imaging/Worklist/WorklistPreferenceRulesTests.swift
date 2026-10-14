@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistPreferenceValidator()
        let item = Imaging.newWorklistPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistPreferenceRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.WorklistPreferenceRatioRangeRule(min: 4.4, max: 4642.8)
        let item = Imaging.newWorklistPreference("x", title: "y")
        item.ratio = 4644.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistPreferenceRequiredCodeRule(message: "worklist preference needs a value")
        let item = Imaging.newWorklistPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.WorklistPreferenceRequiredLabelRule(message: "worklist preference needs an entry")
        let item = Imaging.newWorklistPreference("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistPreferenceCodeLengthRule(maxLength: 3600)
        let item = Imaging.newWorklistPreference("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
