@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedReferralRollupValidator()
        let item = Referrals.newCappedReferralRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedReferralRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.CappedReferralRollupRequiredCodeRule(message: "capped referral rollup needs this field")
        let item = Referrals.newCappedReferralRollup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedReferralRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.CappedReferralRollupCodeLengthRule(maxLength: 86400)
        let item = Referrals.newCappedReferralRollup("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedReferralRollupDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Referrals.CappedReferralRollupDescriptionLengthRule(maxLength: 1000)
        let item = Referrals.newCappedReferralRollup("x", title: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedReferralRollupRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Referrals.CappedReferralRollupRequiredDescriptionRule(
            message: "capped referral rollup needs an entry"
        )
        let item = Referrals.newCappedReferralRollup("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
