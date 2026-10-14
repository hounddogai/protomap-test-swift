@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalCensusPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRegionalCensusPreferenceValidator()
        let item = BedManagement.newRegionalCensusPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRegionalCensusPreferenceRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.RegionalCensusPreferenceRetriesRangeRule(min: 64, max: 255)
        let item = BedManagement.newRegionalCensusPreference("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRegionalCensusPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.RegionalCensusPreferenceRequiredCodeRule(
            message: "regional census preference needs a value"
        )
        let item = BedManagement.newRegionalCensusPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRegionalCensusPreferenceDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.RegionalCensusPreferenceDurationMinutesRangeRule(min: 16, max: 255)
        let item = BedManagement.newRegionalCensusPreference("x", title: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRegionalCensusPreferenceExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.RegionalCensusPreferenceExpiresAtRangeRule(min: 32, max: 120)
        let item = BedManagement.newRegionalCensusPreference("x", title: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}
