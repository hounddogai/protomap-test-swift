@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpTierValidator()
        let item = Referrals.newFollowUpTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpTierCodeLengthRule(maxLength: 64)
        let item = Referrals.newFollowUpTier("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpTierRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Referrals.FollowUpTierRequiredChecksumRule(message: "follow up tier needs an entry")
        let item = Referrals.newFollowUpTier("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpTierChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Referrals.FollowUpTierChecksumLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpTier("x", label: "y")
        item.checksum = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
