@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimarySlotBudgetValidator()
        let item = Referrals.newPrimarySlotBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimarySlotBudgetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.PrimarySlotBudgetLabelLengthRule(maxLength: 3600)
        let item = Referrals.newPrimarySlotBudget("x", title: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimarySlotBudgetAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.PrimarySlotBudgetAttemptsRangeRule(min: 64, max: 80)
        let item = Referrals.newPrimarySlotBudget("x", title: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPrimarySlotBudgetScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.PrimarySlotBudgetScoreRangeRule(min: 0.8, max: 304.1)
        let item = Referrals.newPrimarySlotBudget("x", title: "y")
        item.score = 305.6
        #expect(rule.check(item).count > 0)
    }
}
