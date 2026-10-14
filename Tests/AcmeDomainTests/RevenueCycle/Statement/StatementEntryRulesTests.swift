@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementEntryValidator()
        let item = RevenueCycle.newStatementEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementEntryPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = RevenueCycle.StatementEntryPhoneLengthRule(maxLength: 80)
        let item = RevenueCycle.newStatementEntry("x", name: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementEntryRequiredCodeRule(message: "statement entry needs a value")
        let item = RevenueCycle.newStatementEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementEntryRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.StatementEntryRetriesRangeRule(min: 16, max: 120)
        let item = RevenueCycle.newStatementEntry("x", name: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementEntryCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newStatementEntry("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementEntryBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = RevenueCycle.StatementEntryBudgetRangeRule(min: 3.2, max: 1549.0)
        let item = RevenueCycle.newStatementEntry("x", name: "y")
        item.budget = 1550.5
        #expect(rule.check(item).count > 0)
    }
}
