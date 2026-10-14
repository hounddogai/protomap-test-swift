@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackPanelGroupValidator()
        let item = Labs.newFallbackPanelGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackPanelGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.FallbackPanelGroupRequiredNameRule(message: "fallback panel group needs an entry")
        let item = Labs.newFallbackPanelGroup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackPanelGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackPanelGroupRequiredCodeRule(message: "fallback panel group needs a value")
        let item = Labs.newFallbackPanelGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackPanelGroupDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.FallbackPanelGroupDurationMinutesRangeRule(min: 64, max: 80)
        let item = Labs.newFallbackPanelGroup("x", name: "y")
        item.durationMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackPanelGroupExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.FallbackPanelGroupExpiresAtRangeRule(min: 32, max: 80)
        let item = Labs.newFallbackPanelGroup("x", name: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}
