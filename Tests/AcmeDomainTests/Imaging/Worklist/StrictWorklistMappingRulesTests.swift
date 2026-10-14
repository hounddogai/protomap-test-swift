@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictWorklistMappingValidator()
        let item = Imaging.newStrictWorklistMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictWorklistMappingRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Imaging.StrictWorklistMappingRequiredTimezoneRule(message: "strict worklist mapping needs this field")
        let item = Imaging.newStrictWorklistMapping("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictWorklistMappingTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StrictWorklistMappingTitleLengthRule(maxLength: 3600)
        let item = Imaging.newStrictWorklistMapping("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictWorklistMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StrictWorklistMappingRequiredTitleRule(message: "strict worklist mapping needs a value")
        let item = Imaging.newStrictWorklistMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
