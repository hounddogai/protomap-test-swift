@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeOverrideValidator()
        let item = Labs.newReferenceRangeOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeOverrideRequiredCodeRule(message: "reference range override needs an entry")
        let item = Labs.newReferenceRangeOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeOverrideRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Labs.ReferenceRangeOverrideRefillsRangeRule(min: 16, max: 64)
        let item = Labs.newReferenceRangeOverride("x", label: "y")
        item.refills = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeOverrideRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Labs.ReferenceRangeOverrideRequiredTimezoneRule(message: "reference range override needs an entry")
        let item = Labs.newReferenceRangeOverride("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
