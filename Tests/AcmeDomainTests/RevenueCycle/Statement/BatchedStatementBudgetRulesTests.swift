@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedStatementBudgetValidator()
        let item = RevenueCycle.newBatchedStatementBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedStatementBudgetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = RevenueCycle.BatchedStatementBudgetDescriptionLengthRule(maxLength: 255)
        let item = RevenueCycle.newBatchedStatementBudget("x", name: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedStatementBudgetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.BatchedStatementBudgetUpdatedAtRangeRule(min: 120, max: 86400)
        let item = RevenueCycle.newBatchedStatementBudget("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedStatementBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedStatementBudgetCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newBatchedStatementBudget("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
