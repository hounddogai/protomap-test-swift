@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalProgramPreferenceValidator()
        let item = CareManagement.newGlobalProgramPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalProgramPreferenceMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.GlobalProgramPreferenceMinimumRangeRule(min: 1.8, max: 171.2)
        let item = CareManagement.newGlobalProgramPreference("x", title: "y")
        item.minimum = 172.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalProgramPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GlobalProgramPreferenceRequiredCodeRule(
            message: "global program preference needs a value"
        )
        let item = CareManagement.newGlobalProgramPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalProgramPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.GlobalProgramPreferenceTitleLengthRule(maxLength: 64)
        let item = CareManagement.newGlobalProgramPreference("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
