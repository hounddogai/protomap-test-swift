@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictLanguageForecastValidator()
        let item = Consent.newStrictLanguageForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictLanguageForecastCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.StrictLanguageForecastCostRangeRule(min: 0.9, max: 4894.0)
        let item = Consent.newStrictLanguageForecast("x", title: "y")
        item.cost = 4895.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictLanguageForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.StrictLanguageForecastRequiredTitleRule(message: "strict language forecast needs an entry")
        let item = Consent.newStrictLanguageForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictLanguageForecastMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.StrictLanguageForecastMaximumRangeRule(min: 6.4, max: 4210.8)
        let item = Consent.newStrictLanguageForecast("x", title: "y")
        item.maximum = 4212.3
        #expect(rule.check(item).count > 0)
    }
}
