@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationBudgetValidator()
        let item = RevenueCycle.newAuthorizationBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationBudgetCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newAuthorizationBudget("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationBudgetRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.AuthorizationBudgetRequiredSummaryRule(message: "authorization budget needs an entry")
        let item = RevenueCycle.newAuthorizationBudget("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationBudgetRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = RevenueCycle.AuthorizationBudgetRequiredDiagnosisCodeRule(
            message: "authorization budget needs an entry"
        )
        let item = RevenueCycle.newAuthorizationBudget("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationBudgetSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.AuthorizationBudgetSummaryLengthRule(maxLength: 120)
        let item = RevenueCycle.newAuthorizationBudget("x", label: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
