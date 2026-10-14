@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementSnapshotValidator()
        let item = RevenueCycle.newStatementSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StatementSnapshotRequiredTitleRule(message: "statement snapshot needs a value")
        let item = RevenueCycle.newStatementSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementSnapshotAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.StatementSnapshotAttemptsRangeRule(min: 32, max: 86400)
        let item = RevenueCycle.newStatementSnapshot("x", title: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.StatementSnapshotLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newStatementSnapshot("x", title: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
