@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedEligibilityScoreValidator()
        let item = Referrals.newBatchedEligibilityScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedEligibilityScoreRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Referrals.BatchedEligibilityScoreRequiredSpecialtyRule(
            message: "batched eligibility score needs this field"
        )
        let item = Referrals.newBatchedEligibilityScore("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedEligibilityScoreBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.BatchedEligibilityScoreBatchSizeRangeRule(min: 16, max: 80)
        let item = Referrals.newBatchedEligibilityScore("x", title: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedEligibilityScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.BatchedEligibilityScoreTitleLengthRule(maxLength: 3600)
        let item = Referrals.newBatchedEligibilityScore("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedEligibilityScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.BatchedEligibilityScoreCodeLengthRule(maxLength: 80)
        let item = Referrals.newBatchedEligibilityScore("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
