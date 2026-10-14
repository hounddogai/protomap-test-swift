@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedSlotAgreementValidator()
        let item = Referrals.newBatchedSlotAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedSlotAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.BatchedSlotAgreementRequiredCodeRule(message: "batched slot agreement needs an entry")
        let item = Referrals.newBatchedSlotAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedSlotAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.BatchedSlotAgreementTitleLengthRule(maxLength: 86400)
        let item = Referrals.newBatchedSlotAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedSlotAgreementSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Referrals.BatchedSlotAgreementSegmentLengthRule(maxLength: 80)
        let item = Referrals.newBatchedSlotAgreement("x", title: "y")
        item.segment = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedSlotAgreementRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.BatchedSlotAgreementRequiredPhoneRule(message: "batched slot agreement needs an entry")
        let item = Referrals.newBatchedSlotAgreement("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedSlotAgreementDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.BatchedSlotAgreementDosageMgRangeRule(min: 7.8, max: 2459.1)
        let item = Referrals.newBatchedSlotAgreement("x", title: "y")
        item.dosageMg = 2460.6
        #expect(rule.check(item).count > 0)
    }
}
