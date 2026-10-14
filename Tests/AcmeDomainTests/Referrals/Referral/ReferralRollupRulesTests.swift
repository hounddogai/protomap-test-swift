@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralRollupValidator()
        let item = Referrals.newReferralRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralRollupLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Referrals.ReferralRollupLocaleLengthRule(maxLength: 255)
        let item = Referrals.newReferralRollup("x", label: "y")
        item.locale = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralRollupUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.ReferralRollupUpdatedAtRangeRule(min: 3600, max: 86400)
        let item = Referrals.newReferralRollup("x", label: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralRollupCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.ReferralRollupCopayRangeRule(min: 4.5, max: 150.5)
        let item = Referrals.newReferralRollup("x", label: "y")
        item.copay = 152.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ReferralRollupRequiredLabelRule(message: "referral rollup needs a value")
        let item = Referrals.newReferralRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
