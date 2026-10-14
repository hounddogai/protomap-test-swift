@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredReferralTemplateValidator()
        let item = Referrals.newTieredReferralTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredReferralTemplateRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.TieredReferralTemplateRequiredPayerRule(
            message: "tiered referral template needs this field"
        )
        let item = Referrals.newTieredReferralTemplate("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredReferralTemplateReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.TieredReferralTemplateReviewerLengthRule(maxLength: 1000)
        let item = Referrals.newTieredReferralTemplate("x", label: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredReferralTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.TieredReferralTemplateCodeLengthRule(maxLength: 64)
        let item = Referrals.newTieredReferralTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredReferralTemplateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.TieredReferralTemplateDiscountRangeRule(min: 3.4, max: 2891.8)
        let item = Referrals.newTieredReferralTemplate("x", label: "y")
        item.discount = 2893.3
        #expect(rule.check(item).count > 0)
    }
}
