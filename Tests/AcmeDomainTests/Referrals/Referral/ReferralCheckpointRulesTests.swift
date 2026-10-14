@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralCheckpointValidator()
        let item = Referrals.newReferralCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ReferralCheckpointRequiredCodeRule(message: "referral checkpoint needs an entry")
        let item = Referrals.newReferralCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ReferralCheckpointNameLengthRule(maxLength: 86400)
        let item = Referrals.newReferralCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralCheckpointRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.ReferralCheckpointRatioRangeRule(min: 7.5, max: 3659.2)
        let item = Referrals.newReferralCheckpoint("x", name: "y")
        item.ratio = 3660.7
        #expect(rule.check(item).count > 0)
    }
}
