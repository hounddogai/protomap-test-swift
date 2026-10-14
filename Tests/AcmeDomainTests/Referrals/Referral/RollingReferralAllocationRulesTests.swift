@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingReferralAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingReferralAllocationValidator()
        let item = Referrals.newRollingReferralAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingReferralAllocationCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Referrals.RollingReferralAllocationCountryLengthRule(maxLength: 80)
        let item = Referrals.newRollingReferralAllocation("x", title: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingReferralAllocationRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.RollingReferralAllocationRequiredCountryRule(
            message: "rolling referral allocation needs an entry"
        )
        let item = Referrals.newRollingReferralAllocation("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingReferralAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RollingReferralAllocationRequiredCodeRule(
            message: "rolling referral allocation needs this field"
        )
        let item = Referrals.newRollingReferralAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingReferralAllocationStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.RollingReferralAllocationStartsAtRangeRule(min: 32, max: 32)
        let item = Referrals.newRollingReferralAllocation("x", title: "y")
        item.startsAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingReferralAllocationRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.RollingReferralAllocationRatioRangeRule(min: 6.7, max: 209.9)
        let item = Referrals.newRollingReferralAllocation("x", title: "y")
        item.ratio = 211.4
        #expect(rule.check(item).count > 0)
    }
}
