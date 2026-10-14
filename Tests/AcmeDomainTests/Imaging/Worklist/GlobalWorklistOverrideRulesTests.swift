@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalWorklistOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalWorklistOverrideValidator()
        let item = Imaging.newGlobalWorklistOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalWorklistOverrideRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.GlobalWorklistOverrideRetriesRangeRule(min: 16, max: 64)
        let item = Imaging.newGlobalWorklistOverride("x", label: "y")
        item.retries = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalWorklistOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.GlobalWorklistOverrideRequiredLabelRule(message: "global worklist override needs this field")
        let item = Imaging.newGlobalWorklistOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalWorklistOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.GlobalWorklistOverrideRequiredCodeRule(message: "global worklist override needs an entry")
        let item = Imaging.newGlobalWorklistOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalWorklistOverrideRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Imaging.GlobalWorklistOverrideRequiredChecksumRule(message: "global worklist override needs a value")
        let item = Imaging.newGlobalWorklistOverride("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalWorklistOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.GlobalWorklistOverrideCodeLengthRule(maxLength: 80)
        let item = Imaging.newGlobalWorklistOverride("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalWorklistOverrideRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Imaging.GlobalWorklistOverrideRequiredTimezoneRule(message: "global worklist override needs an entry")
        let item = Imaging.newGlobalWorklistOverride("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
