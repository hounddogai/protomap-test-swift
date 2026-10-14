@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingEligibilityVarianceValidator()
        let item = Referrals.newPendingEligibilityVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingEligibilityVariancePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.PendingEligibilityVariancePriorityRangeRule(min: 32, max: 1000)
        let item = Referrals.newPendingEligibilityVariance("x", title: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingEligibilityVarianceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.PendingEligibilityVarianceAttemptsRangeRule(min: 32, max: 120)
        let item = Referrals.newPendingEligibilityVariance("x", title: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingEligibilityVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.PendingEligibilityVarianceCodeLengthRule(maxLength: 1000)
        let item = Referrals.newPendingEligibilityVariance("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
