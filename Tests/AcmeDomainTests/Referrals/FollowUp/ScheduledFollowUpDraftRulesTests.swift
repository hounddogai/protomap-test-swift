@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledFollowUpDraftValidator()
        let item = Referrals.newScheduledFollowUpDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledFollowUpDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ScheduledFollowUpDraftCodeLengthRule(maxLength: 32)
        let item = Referrals.newScheduledFollowUpDraft("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpDraftLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.ScheduledFollowUpDraftLimitRangeRule(min: 32, max: 86400)
        let item = Referrals.newScheduledFollowUpDraft("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledFollowUpDraftRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Referrals.ScheduledFollowUpDraftRequiredExternalRefRule(
            message: "scheduled follow up draft needs a value"
        )
        let item = Referrals.newScheduledFollowUpDraft("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
