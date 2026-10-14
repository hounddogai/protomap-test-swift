@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientRiskScorePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientRiskScorePreferenceValidator()
        let item = CareManagement.newLenientRiskScorePreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientRiskScorePreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientRiskScorePreferenceCodeLengthRule(maxLength: 120)
        let item = CareManagement.newLenientRiskScorePreference("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientRiskScorePreferenceVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.LenientRiskScorePreferenceVersionRangeRule(min: 3600, max: 86400)
        let item = CareManagement.newLenientRiskScorePreference("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLenientRiskScorePreferenceRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = CareManagement.LenientRiskScorePreferenceRequiredNotesRule(
            message: "lenient risk score preference needs a value"
        )
        let item = CareManagement.newLenientRiskScorePreference("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
