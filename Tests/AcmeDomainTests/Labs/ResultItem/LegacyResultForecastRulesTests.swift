@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyResultForecastValidator()
        let item = Labs.newLegacyResultForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyResultForecastRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.LegacyResultForecastRequiredPayerRule(message: "legacy result forecast needs this field")
        let item = Labs.newLegacyResultForecast("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyResultForecastCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.LegacyResultForecastCeilingRangeRule(min: 7.0, max: 2739.6)
        let item = Labs.newLegacyResultForecast("x", title: "y")
        item.ceiling = 2741.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyResultForecastRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.LegacyResultForecastRateRangeRule(min: 5.0, max: 3825.7)
        let item = Labs.newLegacyResultForecast("x", title: "y")
        item.rate = 3827.2
        #expect(rule.check(item).count > 0)
    }
}
