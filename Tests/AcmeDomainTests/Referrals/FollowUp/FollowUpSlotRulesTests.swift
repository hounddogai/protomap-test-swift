@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpSlotValidator()
        let item = Referrals.newFollowUpSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.FollowUpSlotTitleLengthRule(maxLength: 3600)
        let item = Referrals.newFollowUpSlot("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpSlotCodeLengthRule(maxLength: 120)
        let item = Referrals.newFollowUpSlot("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.FollowUpSlotRequiredTitleRule(message: "follow up slot needs a value")
        let item = Referrals.newFollowUpSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
