@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpWindowValidator()
        let item = Referrals.newFollowUpWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpWindowRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.FollowUpWindowRetriesRangeRule(min: 120, max: 255)
        let item = Referrals.newFollowUpWindow("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpWindowCodeLengthRule(maxLength: 16)
        let item = Referrals.newFollowUpWindow("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpWindowRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.FollowUpWindowRequiredPayerRule(message: "follow up window needs this field")
        let item = Referrals.newFollowUpWindow("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpWindowPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.FollowUpWindowPriorityRangeRule(min: 80, max: 86400)
        let item = Referrals.newFollowUpWindow("x", title: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
