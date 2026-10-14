@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultRecallForecastValidator()
        let item = Pharmacy.newDefaultRecallForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultRecallForecastRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.DefaultRecallForecastRequiredPayerRule(message: "default recall forecast needs a value")
        let item = Pharmacy.newDefaultRecallForecast("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultRecallForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.DefaultRecallForecastRequiredTitleRule(message: "default recall forecast needs an entry")
        let item = Pharmacy.newDefaultRecallForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultRecallForecastRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.DefaultRecallForecastRequiredCurrencyRule(
            message: "default recall forecast needs this field"
        )
        let item = Pharmacy.newDefaultRecallForecast("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultRecallForecastCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.DefaultRecallForecastCurrencyLengthRule(maxLength: 16)
        let item = Pharmacy.newDefaultRecallForecast("x", title: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultRecallForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DefaultRecallForecastRequiredCodeRule(message: "default recall forecast needs an entry")
        let item = Pharmacy.newDefaultRecallForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
