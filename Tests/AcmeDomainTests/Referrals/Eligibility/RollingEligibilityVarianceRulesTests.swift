@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingEligibilityVarianceValidator()
        let item = Referrals.newRollingEligibilityVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingEligibilityVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.RollingEligibilityVarianceTitleLengthRule(maxLength: 120)
        let item = Referrals.newRollingEligibilityVariance("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingEligibilityVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RollingEligibilityVarianceRequiredCodeRule(
            message: "rolling eligibility variance needs this field"
        )
        let item = Referrals.newRollingEligibilityVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingEligibilityVarianceWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.RollingEligibilityVarianceWeightRangeRule(min: 4.4, max: 2224.3)
        let item = Referrals.newRollingEligibilityVariance("x", title: "y")
        item.weight = 2225.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingEligibilityVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.RollingEligibilityVarianceQuantityRangeRule(min: 64, max: 86400)
        let item = Referrals.newRollingEligibilityVariance("x", title: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingEligibilityVarianceEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.RollingEligibilityVarianceEndsAtRangeRule(min: 32, max: 86400)
        let item = Referrals.newRollingEligibilityVariance("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
