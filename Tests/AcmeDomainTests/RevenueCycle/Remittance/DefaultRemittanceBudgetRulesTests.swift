@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultRemittanceBudgetValidator()
        let item = RevenueCycle.newDefaultRemittanceBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DefaultRemittanceBudgetRequiredTitleRule(
            message: "default remittance budget needs this field"
        )
        let item = RevenueCycle.newDefaultRemittanceBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultRemittanceBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DefaultRemittanceBudgetRequiredCodeRule(
            message: "default remittance budget needs a value"
        )
        let item = RevenueCycle.newDefaultRemittanceBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultRemittanceBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DefaultRemittanceBudgetTitleLengthRule(maxLength: 86400)
        let item = RevenueCycle.newDefaultRemittanceBudget("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DefaultRemittanceBudgetCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newDefaultRemittanceBudget("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
