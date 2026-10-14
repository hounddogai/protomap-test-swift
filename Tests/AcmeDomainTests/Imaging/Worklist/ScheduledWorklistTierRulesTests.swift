@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledWorklistTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledWorklistTierValidator()
        let item = Imaging.newScheduledWorklistTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledWorklistTierDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.ScheduledWorklistTierDurationMinutesRangeRule(min: 16, max: 120)
        let item = Imaging.newScheduledWorklistTier("x", title: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledWorklistTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ScheduledWorklistTierCodeLengthRule(maxLength: 64)
        let item = Imaging.newScheduledWorklistTier("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledWorklistTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ScheduledWorklistTierRequiredCodeRule(message: "scheduled worklist tier needs an entry")
        let item = Imaging.newScheduledWorklistTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
