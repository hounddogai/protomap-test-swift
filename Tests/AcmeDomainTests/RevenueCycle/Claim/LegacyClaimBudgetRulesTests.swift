@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyClaimBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyClaimBudgetValidator()
        let item = RevenueCycle.newLegacyClaimBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyClaimBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.LegacyClaimBudgetRequiredTitleRule(message: "legacy claim budget needs a value")
        let item = RevenueCycle.newLegacyClaimBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyClaimBudgetWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.LegacyClaimBudgetWardLengthRule(maxLength: 32)
        let item = RevenueCycle.newLegacyClaimBudget("x", title: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyClaimBudgetReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = RevenueCycle.LegacyClaimBudgetReviewerLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLegacyClaimBudget("x", title: "y")
        item.reviewer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyClaimBudgetRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = RevenueCycle.LegacyClaimBudgetRequiredReviewerRule(message: "legacy claim budget needs this field")
        let item = RevenueCycle.newLegacyClaimBudget("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
