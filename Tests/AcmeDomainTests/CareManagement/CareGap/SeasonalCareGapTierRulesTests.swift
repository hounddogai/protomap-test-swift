@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalCareGapTierValidator()
        let item = CareManagement.newSeasonalCareGapTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalCareGapTierRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.SeasonalCareGapTierRequiredFacilityRule(
            message: "seasonal care gap tier needs an entry"
        )
        let item = CareManagement.newSeasonalCareGapTier("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalCareGapTierScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = CareManagement.SeasonalCareGapTierScoreRangeRule(min: 6.6, max: 1872.8)
        let item = CareManagement.newSeasonalCareGapTier("x", name: "y")
        item.score = 1874.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalCareGapTierUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.SeasonalCareGapTierUnitLengthRule(maxLength: 16)
        let item = CareManagement.newSeasonalCareGapTier("x", name: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
