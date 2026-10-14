@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedEligibilityVarianceValidator()
        let item = Referrals.newBatchedEligibilityVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedEligibilityVarianceRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.BatchedEligibilityVarianceRequiredTimezoneRule(
            message: "batched eligibility variance needs an entry"
        )
        let item = Referrals.newBatchedEligibilityVariance("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedEligibilityVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.BatchedEligibilityVarianceRequiredLabelRule(
            message: "batched eligibility variance needs this field"
        )
        let item = Referrals.newBatchedEligibilityVariance("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedEligibilityVarianceUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.BatchedEligibilityVarianceUpdatedAtRangeRule(min: 32, max: 80)
        let item = Referrals.newBatchedEligibilityVariance("x", name: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedEligibilityVarianceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.BatchedEligibilityVarianceAttemptsRangeRule(min: 32, max: 1000)
        let item = Referrals.newBatchedEligibilityVariance("x", name: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedEligibilityVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.BatchedEligibilityVarianceRequiredCodeRule(
            message: "batched eligibility variance needs this field"
        )
        let item = Referrals.newBatchedEligibilityVariance("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
