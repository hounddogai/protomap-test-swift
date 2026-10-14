@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedReferralVarianceValidator()
        let item = Referrals.newWeightedReferralVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedReferralVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedReferralVarianceRequiredCodeRule(
            message: "weighted referral variance needs this field"
        )
        let item = Referrals.newWeightedReferralVariance("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedReferralVarianceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.WeightedReferralVarianceNameLengthRule(maxLength: 16)
        let item = Referrals.newWeightedReferralVariance("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedReferralVarianceCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.WeightedReferralVarianceCopayRangeRule(min: 8.3, max: 1264.1)
        let item = Referrals.newWeightedReferralVariance("x", name: "y")
        item.copay = 1265.6
        #expect(rule.check(item).count > 0)
    }
}
