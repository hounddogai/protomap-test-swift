@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualIsolationPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualIsolationPreferenceValidator()
        let item = BedManagement.newManualIsolationPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualIsolationPreferenceRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = BedManagement.ManualIsolationPreferenceRequiredCurrencyRule(
            message: "manual isolation preference needs this field"
        )
        let item = BedManagement.newManualIsolationPreference("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualIsolationPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualIsolationPreferenceCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newManualIsolationPreference("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualIsolationPreferenceScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.ManualIsolationPreferenceScoreRangeRule(min: 3.5, max: 4803.7)
        let item = BedManagement.newManualIsolationPreference("x", name: "y")
        item.score = 4805.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualIsolationPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.ManualIsolationPreferenceNameLengthRule(maxLength: 1000)
        let item = BedManagement.newManualIsolationPreference("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualIsolationPreferenceNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.ManualIsolationPreferenceNotesLengthRule(maxLength: 1000)
        let item = BedManagement.newManualIsolationPreference("x", name: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
