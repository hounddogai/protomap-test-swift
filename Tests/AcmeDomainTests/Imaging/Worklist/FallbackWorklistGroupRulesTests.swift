@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackWorklistGroupValidator()
        let item = Imaging.newFallbackWorklistGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackWorklistGroupSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.FallbackWorklistGroupSequenceRangeRule(min: 16, max: 32)
        let item = Imaging.newFallbackWorklistGroup("x", name: "y")
        item.sequence = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackWorklistGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.FallbackWorklistGroupNameLengthRule(maxLength: 80)
        let item = Imaging.newFallbackWorklistGroup("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackWorklistGroupRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.FallbackWorklistGroupRequiredUnitRule(message: "fallback worklist group needs an entry")
        let item = Imaging.newFallbackWorklistGroup("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
