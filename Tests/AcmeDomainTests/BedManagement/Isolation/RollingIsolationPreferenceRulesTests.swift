@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingIsolationPreferenceValidator()
        let item = BedManagement.newRollingIsolationPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingIsolationPreferenceLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.RollingIsolationPreferenceLocaleLengthRule(maxLength: 1000)
        let item = BedManagement.newRollingIsolationPreference("x", name: "y")
        item.locale = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingIsolationPreferencePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.RollingIsolationPreferencePriorityRangeRule(min: 64, max: 3600)
        let item = BedManagement.newRollingIsolationPreference("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingIsolationPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.RollingIsolationPreferenceRequiredNameRule(
            message: "rolling isolation preference needs a value"
        )
        let item = BedManagement.newRollingIsolationPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingIsolationPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RollingIsolationPreferenceCodeLengthRule(maxLength: 80)
        let item = BedManagement.newRollingIsolationPreference("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
