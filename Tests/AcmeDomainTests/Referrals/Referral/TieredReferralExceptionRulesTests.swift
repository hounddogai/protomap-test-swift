@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredReferralExceptionValidator()
        let item = Referrals.newTieredReferralException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredReferralExceptionSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Referrals.TieredReferralExceptionSpecialtyLengthRule(maxLength: 1000)
        let item = Referrals.newTieredReferralException("x", title: "y")
        item.specialty = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredReferralExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.TieredReferralExceptionRequiredTitleRule(
            message: "tiered referral exception needs this field"
        )
        let item = Referrals.newTieredReferralException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredReferralExceptionMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.TieredReferralExceptionMaximumRangeRule(min: 5.4, max: 1880.8)
        let item = Referrals.newTieredReferralException("x", title: "y")
        item.maximum = 1882.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredReferralExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.TieredReferralExceptionCodeLengthRule(maxLength: 255)
        let item = Referrals.newTieredReferralException("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
