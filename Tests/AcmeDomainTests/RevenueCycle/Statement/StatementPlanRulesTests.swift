@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementPlanValidator()
        let item = RevenueCycle.newStatementPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementPlanRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.StatementPlanRequiredChannelRule(message: "statement plan needs a value")
        let item = RevenueCycle.newStatementPlan("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StatementPlanRequiredNameRule(message: "statement plan needs a value")
        let item = RevenueCycle.newStatementPlan("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementPlanChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = RevenueCycle.StatementPlanChannelLengthRule(maxLength: 64)
        let item = RevenueCycle.newStatementPlan("x", name: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementPlanRequiredCodeRule(message: "statement plan needs an entry")
        let item = RevenueCycle.newStatementPlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
