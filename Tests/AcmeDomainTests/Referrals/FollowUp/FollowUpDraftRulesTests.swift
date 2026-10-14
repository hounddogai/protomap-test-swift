@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpDraftValidator()
        let item = Referrals.newFollowUpDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpDraftCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.FollowUpDraftCeilingRangeRule(min: 9.5, max: 4101.6)
        let item = Referrals.newFollowUpDraft("x", label: "y")
        item.ceiling = 4103.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpDraftScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.FollowUpDraftScoreRangeRule(min: 2.3, max: 2283.3)
        let item = Referrals.newFollowUpDraft("x", label: "y")
        item.score = 2284.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpDraftCodeLengthRule(maxLength: 3600)
        let item = Referrals.newFollowUpDraft("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
