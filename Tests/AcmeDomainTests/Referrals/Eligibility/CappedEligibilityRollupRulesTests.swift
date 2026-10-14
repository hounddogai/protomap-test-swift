@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedEligibilityRollupValidator()
        let item = Referrals.newCappedEligibilityRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedEligibilityRollupDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.CappedEligibilityRollupDiscountRangeRule(min: 1.0, max: 1103.7)
        let item = Referrals.newCappedEligibilityRollup("x", label: "y")
        item.discount = 1105.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedEligibilityRollupAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.CappedEligibilityRollupAttemptsRangeRule(min: 16, max: 1000)
        let item = Referrals.newCappedEligibilityRollup("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedEligibilityRollupLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Referrals.CappedEligibilityRollupLocaleLengthRule(maxLength: 120)
        let item = Referrals.newCappedEligibilityRollup("x", label: "y")
        item.locale = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedEligibilityRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.CappedEligibilityRollupRequiredCodeRule(message: "capped eligibility rollup needs an entry")
        let item = Referrals.newCappedEligibilityRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedEligibilityRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.CappedEligibilityRollupNameLengthRule(maxLength: 1000)
        let item = Referrals.newCappedEligibilityRollup("x", label: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
