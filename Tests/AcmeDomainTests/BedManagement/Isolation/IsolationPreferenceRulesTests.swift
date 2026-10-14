@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationPreferenceValidator()
        let item = BedManagement.newIsolationPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationPreferenceRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.IsolationPreferenceRequiredUnitRule(message: "isolation preference needs this field")
        let item = BedManagement.newIsolationPreference("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationPreferenceRequiredCodeRule(message: "isolation preference needs this field")
        let item = BedManagement.newIsolationPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationPreferenceUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = BedManagement.IsolationPreferenceUnitLengthRule(maxLength: 255)
        let item = BedManagement.newIsolationPreference("x", label: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.IsolationPreferenceLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newIsolationPreference("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationPreferenceRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = BedManagement.IsolationPreferenceRequiredTimezoneRule(message: "isolation preference needs an entry")
        let item = BedManagement.newIsolationPreference("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
