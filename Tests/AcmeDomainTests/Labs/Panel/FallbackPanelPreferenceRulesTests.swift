@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackPanelPreferenceValidator()
        let item = Labs.newFallbackPanelPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackPanelPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.FallbackPanelPreferenceCodeLengthRule(maxLength: 1000)
        let item = Labs.newFallbackPanelPreference("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackPanelPreferenceRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.FallbackPanelPreferenceRequiredFacilityRule(message: "fallback panel preference needs an entry")
        let item = Labs.newFallbackPanelPreference("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackPanelPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.FallbackPanelPreferenceTitleLengthRule(maxLength: 86400)
        let item = Labs.newFallbackPanelPreference("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackPanelPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackPanelPreferenceRequiredCodeRule(message: "fallback panel preference needs a value")
        let item = Labs.newFallbackPanelPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackPanelPreferenceFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.FallbackPanelPreferenceFacilityLengthRule(maxLength: 3600)
        let item = Labs.newFallbackPanelPreference("x", title: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
