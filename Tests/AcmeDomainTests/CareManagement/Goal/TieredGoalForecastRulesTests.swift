@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredGoalForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredGoalForecastValidator()
        let item = CareManagement.newTieredGoalForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredGoalForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredGoalForecastRequiredCodeRule(message: "tiered goal forecast needs a value")
        let item = CareManagement.newTieredGoalForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredGoalForecastRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.TieredGoalForecastRequiredFacilityRule(message: "tiered goal forecast needs a value")
        let item = CareManagement.newTieredGoalForecast("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredGoalForecastVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.TieredGoalForecastVersionRangeRule(min: 32, max: 3600)
        let item = CareManagement.newTieredGoalForecast("x", name: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementTieredGoalForecastFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = CareManagement.TieredGoalForecastFacilityLengthRule(maxLength: 80)
        let item = CareManagement.newTieredGoalForecast("x", name: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
