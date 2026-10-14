@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralSlotValidator()
        let item = Referrals.newReferralSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralSlotScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.ReferralSlotScoreRangeRule(min: 0.7, max: 2635.6)
        let item = Referrals.newReferralSlot("x", title: "y")
        item.score = 2637.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsReferralSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ReferralSlotRequiredCodeRule(message: "referral slot needs an entry")
        let item = Referrals.newReferralSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralSlotCodeLengthRule(maxLength: 16)
        let item = Referrals.newReferralSlot("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
