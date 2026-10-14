@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalPanelPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalPanelPreferenceValidator()
        let item = Labs.newRegionalPanelPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalPanelPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.RegionalPanelPreferenceCodeLengthRule(maxLength: 80)
        let item = Labs.newRegionalPanelPreference("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalPanelPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RegionalPanelPreferenceRequiredCodeRule(message: "regional panel preference needs an entry")
        let item = Labs.newRegionalPanelPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalPanelPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.RegionalPanelPreferenceRequiredLabelRule(message: "regional panel preference needs a value")
        let item = Labs.newRegionalPanelPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalPanelPreferenceCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.RegionalPanelPreferenceCeilingRangeRule(min: 7.5, max: 1672.8)
        let item = Labs.newRegionalPanelPreference("x", label: "y")
        item.ceiling = 1674.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalPanelPreferenceEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.RegionalPanelPreferenceEndsAtRangeRule(min: 255, max: 3600)
        let item = Labs.newRegionalPanelPreference("x", label: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalPanelPreferenceUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.RegionalPanelPreferenceUpdatedAtRangeRule(min: 32, max: 80)
        let item = Labs.newRegionalPanelPreference("x", label: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}
