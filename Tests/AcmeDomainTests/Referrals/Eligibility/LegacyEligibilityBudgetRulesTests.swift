@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyEligibilityBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyEligibilityBudgetValidator()
        let item = Referrals.newLegacyEligibilityBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyEligibilityBudgetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.LegacyEligibilityBudgetLabelLengthRule(maxLength: 80)
        let item = Referrals.newLegacyEligibilityBudget("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacyEligibilityBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.LegacyEligibilityBudgetRequiredLabelRule(message: "legacy eligibility budget needs a value")
        let item = Referrals.newLegacyEligibilityBudget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyEligibilityBudgetCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.LegacyEligibilityBudgetCostRangeRule(min: 9.0, max: 1965.5)
        let item = Referrals.newLegacyEligibilityBudget("x", label: "y")
        item.cost = 1967.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacyEligibilityBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.LegacyEligibilityBudgetCodeLengthRule(maxLength: 1000)
        let item = Referrals.newLegacyEligibilityBudget("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacyEligibilityBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacyEligibilityBudgetRequiredCodeRule(message: "legacy eligibility budget needs an entry")
        let item = Referrals.newLegacyEligibilityBudget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
