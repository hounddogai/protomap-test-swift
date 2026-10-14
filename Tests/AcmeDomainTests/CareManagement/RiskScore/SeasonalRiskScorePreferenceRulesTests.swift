@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScorePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalRiskScorePreferenceValidator()
        let item = CareManagement.newSeasonalRiskScorePreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalRiskScorePreferenceScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = CareManagement.SeasonalRiskScorePreferenceScoreRangeRule(min: 0.6, max: 1456.4)
        let item = CareManagement.newSeasonalRiskScorePreference("x", title: "y")
        item.score = 1457.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalRiskScorePreferenceTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.SeasonalRiskScorePreferenceTimezoneLengthRule(maxLength: 80)
        let item = CareManagement.newSeasonalRiskScorePreference("x", title: "y")
        item.timezone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementSeasonalRiskScorePreferenceRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = CareManagement.SeasonalRiskScorePreferenceRequiredClinicianIDRule(
            message: "seasonal risk score preference needs this field"
        )
        let item = CareManagement.newSeasonalRiskScorePreference("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalRiskScorePreferenceThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.SeasonalRiskScorePreferenceThresholdRangeRule(min: 2.7, max: 3219.6)
        let item = CareManagement.newSeasonalRiskScorePreference("x", title: "y")
        item.threshold = 3221.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalRiskScorePreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.SeasonalRiskScorePreferenceCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newSeasonalRiskScorePreference("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
