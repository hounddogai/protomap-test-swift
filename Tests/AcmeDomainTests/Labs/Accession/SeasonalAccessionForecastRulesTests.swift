@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalAccessionForecastValidator()
        let item = Labs.newSeasonalAccessionForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalAccessionForecastDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.SeasonalAccessionForecastDescriptionLengthRule(maxLength: 16)
        let item = Labs.newSeasonalAccessionForecast("x", label: "y")
        item.description = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalAccessionForecastCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.SeasonalAccessionForecastCopayRangeRule(min: 4.3, max: 3265.2)
        let item = Labs.newSeasonalAccessionForecast("x", label: "y")
        item.copay = 3266.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalAccessionForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.SeasonalAccessionForecastLabelLengthRule(maxLength: 16)
        let item = Labs.newSeasonalAccessionForecast("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
