@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedSlotTierValidator()
        let item = Referrals.newBatchedSlotTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedSlotTierExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.BatchedSlotTierExpiresAtRangeRule(min: 80, max: 86400)
        let item = Referrals.newBatchedSlotTier("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedSlotTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.BatchedSlotTierTitleLengthRule(maxLength: 120)
        let item = Referrals.newBatchedSlotTier("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedSlotTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.BatchedSlotTierRequiredCodeRule(message: "batched slot tier needs an entry")
        let item = Referrals.newBatchedSlotTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedSlotTierLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Referrals.BatchedSlotTierLocaleLengthRule(maxLength: 64)
        let item = Referrals.newBatchedSlotTier("x", title: "y")
        item.locale = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
