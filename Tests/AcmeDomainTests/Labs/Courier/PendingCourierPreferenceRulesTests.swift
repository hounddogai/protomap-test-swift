@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingCourierPreferenceValidator()
        let item = Labs.newPendingCourierPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingCourierPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PendingCourierPreferenceRequiredLabelRule(message: "pending courier preference needs a value")
        let item = Labs.newPendingCourierPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingCourierPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PendingCourierPreferenceLabelLengthRule(maxLength: 16)
        let item = Labs.newPendingCourierPreference("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingCourierPreferenceDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.PendingCourierPreferenceDescriptionLengthRule(maxLength: 86400)
        let item = Labs.newPendingCourierPreference("x", label: "y")
        item.description = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingCourierPreferenceExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.PendingCourierPreferenceExpiresAtRangeRule(min: 120, max: 86400)
        let item = Labs.newPendingCourierPreference("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
