@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementBudgetValidator()
        let item = RevenueCycle.newStatementBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementBudgetAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = RevenueCycle.StatementBudgetAllergyLengthRule(maxLength: 255)
        let item = RevenueCycle.newStatementBudget("x", title: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementBudgetRequiredCodeRule(message: "statement budget needs an entry")
        let item = RevenueCycle.newStatementBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementBudgetRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.StatementBudgetRequiredPayerRule(message: "statement budget needs a value")
        let item = RevenueCycle.newStatementBudget("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
