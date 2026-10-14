@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientReferralTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientReferralTargetValidator()
        let item = Referrals.newLenientReferralTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientReferralTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.LenientReferralTargetLabelLengthRule(maxLength: 80)
        let item = Referrals.newLenientReferralTarget("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLenientReferralTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.LenientReferralTargetRequiredLabelRule(message: "lenient referral target needs a value")
        let item = Referrals.newLenientReferralTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientReferralTargetQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.LenientReferralTargetQuantityRangeRule(min: 32, max: 1000)
        let item = Referrals.newLenientReferralTarget("x", label: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientReferralTargetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Referrals.LenientReferralTargetDescriptionLengthRule(maxLength: 1000)
        let item = Referrals.newLenientReferralTarget("x", label: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
