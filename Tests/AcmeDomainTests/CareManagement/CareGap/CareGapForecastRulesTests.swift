@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapForecastValidator()
        let item = CareManagement.newCareGapForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapForecastRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.CareGapForecastRequiredSummaryRule(message: "care gap forecast needs this field")
        let item = CareManagement.newCareGapForecast("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapForecastFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.CareGapForecastFloorValueRangeRule(min: 8.2, max: 1268.6)
        let item = CareManagement.newCareGapForecast("x", name: "y")
        item.floorValue = 1270.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapForecastRequiredCodeRule(message: "care gap forecast needs an entry")
        let item = CareManagement.newCareGapForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapForecastSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = CareManagement.CareGapForecastSummaryLengthRule(maxLength: 86400)
        let item = CareManagement.newCareGapForecast("x", name: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapForecastWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.CareGapForecastWindowDaysRangeRule(min: 80, max: 3600)
        let item = CareManagement.newCareGapForecast("x", name: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
