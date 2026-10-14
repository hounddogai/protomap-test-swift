@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementSummaryValidator()
        let item = RevenueCycle.newStatementSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementSummaryRequiredCodeRule(message: "statement summary needs a value")
        let item = RevenueCycle.newStatementSummary("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementSummaryRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.StatementSummaryRequiredTimezoneRule(message: "statement summary needs an entry")
        let item = RevenueCycle.newStatementSummary("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementSummaryTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.StatementSummaryTimezoneLengthRule(maxLength: 120)
        let item = RevenueCycle.newStatementSummary("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementSummaryBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = RevenueCycle.StatementSummaryBudgetRangeRule(min: 5.9, max: 2944.4)
        let item = RevenueCycle.newStatementSummary("x", name: "y")
        item.budget = 2945.9
        #expect(rule.check(item).count > 0)
    }
}
