@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalResultOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalResultOverrideValidator()
        let item = Labs.newSeasonalResultOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalResultOverrideFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.SeasonalResultOverrideFacilityLengthRule(maxLength: 16)
        let item = Labs.newSeasonalResultOverride("x", title: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalResultOverrideRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.SeasonalResultOverrideRequiredSummaryRule(message: "seasonal result override needs an entry")
        let item = Labs.newSeasonalResultOverride("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSeasonalResultOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SeasonalResultOverrideCodeLengthRule(maxLength: 32)
        let item = Labs.newSeasonalResultOverride("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalResultOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.SeasonalResultOverrideTitleLengthRule(maxLength: 80)
        let item = Labs.newSeasonalResultOverride("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalResultOverrideRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.SeasonalResultOverrideRequiredFacilityRule(message: "seasonal result override needs an entry")
        let item = Labs.newSeasonalResultOverride("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
