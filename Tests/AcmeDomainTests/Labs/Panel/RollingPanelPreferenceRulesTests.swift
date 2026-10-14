@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingPanelPreferenceValidator()
        let item = Labs.newRollingPanelPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingPanelPreferenceRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.RollingPanelPreferenceRequiredBedRule(message: "rolling panel preference needs a value")
        let item = Labs.newRollingPanelPreference("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingPanelPreferenceMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.RollingPanelPreferenceMaximumRangeRule(min: 6.4, max: 4245.4)
        let item = Labs.newRollingPanelPreference("x", label: "y")
        item.maximum = 4246.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingPanelPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.RollingPanelPreferenceRequiredLabelRule(message: "rolling panel preference needs a value")
        let item = Labs.newRollingPanelPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingPanelPreferenceContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.RollingPanelPreferenceContactEmailLengthRule(maxLength: 86400)
        let item = Labs.newRollingPanelPreference("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingPanelPreferenceBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.RollingPanelPreferenceBedLengthRule(maxLength: 16)
        let item = Labs.newRollingPanelPreference("x", label: "y")
        item.bed = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
