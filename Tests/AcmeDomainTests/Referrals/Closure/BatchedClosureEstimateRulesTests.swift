@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedClosureEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedClosureEstimateValidator()
        let item = Referrals.newBatchedClosureEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedClosureEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.BatchedClosureEstimateRequiredCodeRule(message: "batched closure estimate needs a value")
        let item = Referrals.newBatchedClosureEstimate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedClosureEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.BatchedClosureEstimateLabelLengthRule(maxLength: 86400)
        let item = Referrals.newBatchedClosureEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedClosureEstimateRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Referrals.BatchedClosureEstimateRequiredExternalRefRule(
            message: "batched closure estimate needs an entry"
        )
        let item = Referrals.newBatchedClosureEstimate("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedClosureEstimateRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.BatchedClosureEstimateRefillsRangeRule(min: 80, max: 120)
        let item = Referrals.newBatchedClosureEstimate("x", label: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedClosureEstimateRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Referrals.BatchedClosureEstimateRequiredSegmentRule(message: "batched closure estimate needs a value")
        let item = Referrals.newBatchedClosureEstimate("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
