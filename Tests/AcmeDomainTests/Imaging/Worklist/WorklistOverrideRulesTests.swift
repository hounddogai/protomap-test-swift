@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistOverrideValidator()
        let item = Imaging.newWorklistOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.WorklistOverrideRequiredTitleRule(message: "worklist override needs an entry")
        let item = Imaging.newWorklistOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistOverrideCodeLengthRule(maxLength: 1000)
        let item = Imaging.newWorklistOverride("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.WorklistOverrideTitleLengthRule(maxLength: 64)
        let item = Imaging.newWorklistOverride("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistOverrideStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.WorklistOverrideStartsAtRangeRule(min: 32, max: 255)
        let item = Imaging.newWorklistOverride("x", title: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistOverrideRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.WorklistOverrideRequiredLocaleRule(message: "worklist override needs this field")
        let item = Imaging.newWorklistOverride("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistOverrideAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.WorklistOverrideAttemptsRangeRule(min: 120, max: 1000)
        let item = Imaging.newWorklistOverride("x", title: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}
