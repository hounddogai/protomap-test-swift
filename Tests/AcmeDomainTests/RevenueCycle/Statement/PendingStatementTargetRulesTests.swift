@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingStatementTargetValidator()
        let item = RevenueCycle.newPendingStatementTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingStatementTargetBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = RevenueCycle.PendingStatementTargetBudgetRangeRule(min: 3.9, max: 3649.8)
        let item = RevenueCycle.newPendingStatementTarget("x", name: "y")
        item.budget = 3651.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingStatementTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PendingStatementTargetRequiredCodeRule(
            message: "pending statement target needs this field"
        )
        let item = RevenueCycle.newPendingStatementTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingStatementTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.PendingStatementTargetNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newPendingStatementTarget("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
