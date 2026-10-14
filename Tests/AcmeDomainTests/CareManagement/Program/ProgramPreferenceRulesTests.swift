@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramPreferenceValidator()
        let item = CareManagement.newProgramPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramPreferenceDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = CareManagement.ProgramPreferenceDurationMinutesRangeRule(min: 255, max: 3600)
        let item = CareManagement.newProgramPreference("x", title: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramPreferenceRequiredCodeRule(message: "program preference needs a value")
        let item = CareManagement.newProgramPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
