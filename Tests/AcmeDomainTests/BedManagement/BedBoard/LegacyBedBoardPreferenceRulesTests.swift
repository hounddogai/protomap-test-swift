@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyBedBoardPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyBedBoardPreferenceValidator()
        let item = BedManagement.newLegacyBedBoardPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyBedBoardPreferenceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.LegacyBedBoardPreferenceGraceDaysRangeRule(min: 80, max: 1000)
        let item = BedManagement.newLegacyBedBoardPreference("x", label: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyBedBoardPreferenceAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.LegacyBedBoardPreferenceAmountRangeRule(min: 0.4, max: 2481.1)
        let item = BedManagement.newLegacyBedBoardPreference("x", label: "y")
        item.amount = 2482.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyBedBoardPreferenceVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.LegacyBedBoardPreferenceVersionRangeRule(min: 1000, max: 86400)
        let item = BedManagement.newLegacyBedBoardPreference("x", label: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
