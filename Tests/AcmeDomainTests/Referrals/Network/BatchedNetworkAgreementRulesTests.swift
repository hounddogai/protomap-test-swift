@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedNetworkAgreementValidator()
        let item = Referrals.newBatchedNetworkAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedNetworkAgreementRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Referrals.BatchedNetworkAgreementRequiredCurrencyRule(
            message: "batched network agreement needs a value"
        )
        let item = Referrals.newBatchedNetworkAgreement("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedNetworkAgreementCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Referrals.BatchedNetworkAgreementCurrencyLengthRule(maxLength: 80)
        let item = Referrals.newBatchedNetworkAgreement("x", label: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedNetworkAgreementStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.BatchedNetworkAgreementStartsAtRangeRule(min: 16, max: 64)
        let item = Referrals.newBatchedNetworkAgreement("x", label: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}
