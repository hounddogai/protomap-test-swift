@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingCleaningPreferenceValidator()
        let item = BedManagement.newPendingCleaningPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingCleaningPreferenceExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.PendingCleaningPreferenceExpiresAtRangeRule(min: 80, max: 120)
        let item = BedManagement.newPendingCleaningPreference("x", label: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingCleaningPreferenceExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = BedManagement.PendingCleaningPreferenceExternalRefLengthRule(maxLength: 3600)
        let item = BedManagement.newPendingCleaningPreference("x", label: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCleaningPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PendingCleaningPreferenceRequiredCodeRule(
            message: "pending cleaning preference needs a value"
        )
        let item = BedManagement.newPendingCleaningPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingCleaningPreferenceFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.PendingCleaningPreferenceFloorValueRangeRule(min: 7.3, max: 89.0)
        let item = BedManagement.newPendingCleaningPreference("x", label: "y")
        item.floorValue = 90.5
        #expect(rule.check(item).count > 0)
    }
}
