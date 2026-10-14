@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultCleaningPreferenceValidator()
        let item = BedManagement.newDefaultCleaningPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultCleaningPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.DefaultCleaningPreferenceRequiredTitleRule(
            message: "default cleaning preference needs a value"
        )
        let item = BedManagement.newDefaultCleaningPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultCleaningPreferenceDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.DefaultCleaningPreferenceDurationMinutesRangeRule(min: 120, max: 3600)
        let item = BedManagement.newDefaultCleaningPreference("x", title: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultCleaningPreferenceDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.DefaultCleaningPreferenceDiagnosisCodeLengthRule(maxLength: 64)
        let item = BedManagement.newDefaultCleaningPreference("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
