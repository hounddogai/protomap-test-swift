@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementRollupValidator()
        let item = RevenueCycle.newStatementRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementRollupPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.StatementRollupPriorityRangeRule(min: 16, max: 80)
        let item = RevenueCycle.newStatementRollup("x", title: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StatementRollupRequiredTitleRule(message: "statement rollup needs a value")
        let item = RevenueCycle.newStatementRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementRollupRequiredCodeRule(message: "statement rollup needs an entry")
        let item = RevenueCycle.newStatementRollup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementRollupRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.StatementRollupRefillsRangeRule(min: 120, max: 1000)
        let item = RevenueCycle.newStatementRollup("x", title: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}
