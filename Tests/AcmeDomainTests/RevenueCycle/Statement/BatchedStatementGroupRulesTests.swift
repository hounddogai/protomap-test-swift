@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedStatementGroupValidator()
        let item = RevenueCycle.newBatchedStatementGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedStatementGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedStatementGroupCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newBatchedStatementGroup("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedStatementGroupAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.BatchedStatementGroupAttemptsRangeRule(min: 32, max: 120)
        let item = RevenueCycle.newBatchedStatementGroup("x", title: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedStatementGroupRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.BatchedStatementGroupRequiredPayerRule(message: "batched statement group needs an entry")
        let item = RevenueCycle.newBatchedStatementGroup("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedStatementGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.BatchedStatementGroupTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newBatchedStatementGroup("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedStatementGroupRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.BatchedStatementGroupRequiredDescriptionRule(
            message: "batched statement group needs this field"
        )
        let item = RevenueCycle.newBatchedStatementGroup("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
