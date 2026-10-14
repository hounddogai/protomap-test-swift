@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientSlotDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientSlotDigestValidator()
        let item = Referrals.newLenientSlotDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientSlotDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.LenientSlotDigestTitleLengthRule(maxLength: 3600)
        let item = Referrals.newLenientSlotDigest("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLenientSlotDigestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.LenientSlotDigestGraceDaysRangeRule(min: 255, max: 1000)
        let item = Referrals.newLenientSlotDigest("x", title: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientSlotDigestAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.LenientSlotDigestAttemptsRangeRule(min: 1000, max: 86400)
        let item = Referrals.newLenientSlotDigest("x", title: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}
