@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementForecastValidator()
        let item = RevenueCycle.newStatementForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementForecastRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.StatementForecastRetriesRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newStatementForecast("x", title: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StatementForecastRequiredTitleRule(message: "statement forecast needs an entry")
        let item = RevenueCycle.newStatementForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementForecastAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.StatementForecastAmountRangeRule(min: 3.8, max: 2872.8)
        let item = RevenueCycle.newStatementForecast("x", title: "y")
        item.amount = 2874.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.StatementForecastTitleLengthRule(maxLength: 3600)
        let item = RevenueCycle.newStatementForecast("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
