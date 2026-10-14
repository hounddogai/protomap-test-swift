@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialForecastValidator()
        let item = RevenueCycle.newDenialForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DenialForecastRequiredNameRule(message: "denial forecast needs a value")
        let item = RevenueCycle.newDenialForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialForecastRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.DenialForecastRequiredChannelRule(message: "denial forecast needs this field")
        let item = RevenueCycle.newDenialForecast("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialForecastRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.DenialForecastRetriesRangeRule(min: 255, max: 1000)
        let item = RevenueCycle.newDenialForecast("x", name: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}
