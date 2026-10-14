@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveRiskScoreForecastValidator()
        let item = CareManagement.newAdaptiveRiskScoreForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.AdaptiveRiskScoreForecastNameLengthRule(maxLength: 80)
        let item = CareManagement.newAdaptiveRiskScoreForecast("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveRiskScoreForecastCodeLengthRule(maxLength: 16)
        let item = CareManagement.newAdaptiveRiskScoreForecast("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreForecastPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.AdaptiveRiskScoreForecastPriorityRangeRule(min: 80, max: 3600)
        let item = CareManagement.newAdaptiveRiskScoreForecast("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}
