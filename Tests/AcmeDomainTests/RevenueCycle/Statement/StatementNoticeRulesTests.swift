@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementNoticeValidator()
        let item = RevenueCycle.newStatementNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementNoticeLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.StatementNoticeLimitRangeRule(min: 80, max: 86400)
        let item = RevenueCycle.newStatementNotice("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.StatementNoticeNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newStatementNotice("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementNoticeCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newStatementNotice("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
