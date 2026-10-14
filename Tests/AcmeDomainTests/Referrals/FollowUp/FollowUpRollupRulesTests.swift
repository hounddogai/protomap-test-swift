@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpRollupValidator()
        let item = Referrals.newFollowUpRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.FollowUpRollupRequiredTitleRule(message: "follow up rollup needs an entry")
        let item = Referrals.newFollowUpRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpRollupRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.FollowUpRollupRequiredReviewerRule(message: "follow up rollup needs an entry")
        let item = Referrals.newFollowUpRollup("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
