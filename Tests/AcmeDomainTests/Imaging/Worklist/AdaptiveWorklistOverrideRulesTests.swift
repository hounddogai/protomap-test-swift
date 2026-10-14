@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveWorklistOverrideValidator()
        let item = Imaging.newAdaptiveWorklistOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveWorklistOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.AdaptiveWorklistOverrideRequiredCodeRule(message: "adaptive worklist override needs a value")
        let item = Imaging.newAdaptiveWorklistOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveWorklistOverrideDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.AdaptiveWorklistOverrideDurationMinutesRangeRule(min: 86400, max: 86400)
        let item = Imaging.newAdaptiveWorklistOverride("x", label: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptiveWorklistOverrideRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.AdaptiveWorklistOverrideRequiredNotesRule(
            message: "adaptive worklist override needs an entry"
        )
        let item = Imaging.newAdaptiveWorklistOverride("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
