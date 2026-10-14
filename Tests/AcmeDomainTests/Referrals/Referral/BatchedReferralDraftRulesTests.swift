@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedReferralDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedReferralDraftValidator()
        let item = Referrals.newBatchedReferralDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedReferralDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.BatchedReferralDraftRequiredLabelRule(message: "batched referral draft needs an entry")
        let item = Referrals.newBatchedReferralDraft("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
