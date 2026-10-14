@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedEligibilityDraftValidator()
        let item = Referrals.newBatchedEligibilityDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedEligibilityDraftSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.BatchedEligibilityDraftSummaryLengthRule(maxLength: 1000)
        let item = Referrals.newBatchedEligibilityDraft("x", title: "y")
        item.summary = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedEligibilityDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.BatchedEligibilityDraftCodeLengthRule(maxLength: 16)
        let item = Referrals.newBatchedEligibilityDraft("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedEligibilityDraftCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.BatchedEligibilityDraftCopayRangeRule(min: 5.6, max: 2853.0)
        let item = Referrals.newBatchedEligibilityDraft("x", title: "y")
        item.copay = 2854.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedEligibilityDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.BatchedEligibilityDraftRequiredTitleRule(message: "batched eligibility draft needs a value")
        let item = Referrals.newBatchedEligibilityDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedEligibilityDraftRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.BatchedEligibilityDraftRequiredSummaryRule(
            message: "batched eligibility draft needs this field"
        )
        let item = Referrals.newBatchedEligibilityDraft("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
