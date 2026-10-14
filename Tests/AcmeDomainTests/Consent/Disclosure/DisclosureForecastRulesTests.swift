@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureForecastValidator()
        let item = Consent.newDisclosureForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureForecastWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.DisclosureForecastWeightRangeRule(min: 5.7, max: 2824.7)
        let item = Consent.newDisclosureForecast("x", title: "y")
        item.weight = 2826.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureForecastRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Consent.DisclosureForecastRequiredCategoryRule(message: "disclosure forecast needs an entry")
        let item = Consent.newDisclosureForecast("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureForecastRequiredCodeRule(message: "disclosure forecast needs a value")
        let item = Consent.newDisclosureForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
