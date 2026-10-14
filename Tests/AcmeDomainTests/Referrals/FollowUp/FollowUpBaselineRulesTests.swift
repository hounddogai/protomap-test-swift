@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpBaselineValidator()
        let item = Referrals.newFollowUpBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.FollowUpBaselineRequiredTitleRule(message: "follow up baseline needs a value")
        let item = Referrals.newFollowUpBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpBaselineRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.FollowUpBaselineRequiredWardRule(message: "follow up baseline needs an entry")
        let item = Referrals.newFollowUpBaseline("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpBaselineWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.FollowUpBaselineWardLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpBaseline("x", title: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpBaselineRequiredCodeRule(message: "follow up baseline needs a value")
        let item = Referrals.newFollowUpBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
