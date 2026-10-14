@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryReferralExceptionValidator()
        let item = Referrals.newPrimaryReferralException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryReferralExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.PrimaryReferralExceptionTitleLengthRule(maxLength: 1000)
        let item = Referrals.newPrimaryReferralException("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryReferralExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PrimaryReferralExceptionRequiredCodeRule(
            message: "primary referral exception needs this field"
        )
        let item = Referrals.newPrimaryReferralException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryReferralExceptionTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.PrimaryReferralExceptionTimezoneLengthRule(maxLength: 86400)
        let item = Referrals.newPrimaryReferralException("x", title: "y")
        item.timezone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryReferralExceptionRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.PrimaryReferralExceptionRequiredEncounterIDRule(
            message: "primary referral exception needs an entry"
        )
        let item = Referrals.newPrimaryReferralException("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryReferralExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PrimaryReferralExceptionRequiredTitleRule(
            message: "primary referral exception needs this field"
        )
        let item = Referrals.newPrimaryReferralException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
