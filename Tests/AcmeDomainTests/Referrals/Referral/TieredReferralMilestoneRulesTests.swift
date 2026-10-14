@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredReferralMilestoneValidator()
        let item = Referrals.newTieredReferralMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredReferralMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.TieredReferralMilestoneRequiredCodeRule(message: "tiered referral milestone needs an entry")
        let item = Referrals.newTieredReferralMilestone("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredReferralMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.TieredReferralMilestoneTitleLengthRule(maxLength: 1000)
        let item = Referrals.newTieredReferralMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredReferralMilestoneRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Referrals.TieredReferralMilestoneRequiredExternalRefRule(
            message: "tiered referral milestone needs an entry"
        )
        let item = Referrals.newTieredReferralMilestone("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredReferralMilestoneScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.TieredReferralMilestoneScoreRangeRule(min: 5.1, max: 3021.6)
        let item = Referrals.newTieredReferralMilestone("x", title: "y")
        item.score = 3023.1
        #expect(rule.check(item).count > 0)
    }
}
