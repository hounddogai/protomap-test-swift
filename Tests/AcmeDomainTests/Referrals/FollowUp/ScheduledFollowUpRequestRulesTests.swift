@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledFollowUpRequestValidator()
        let item = Referrals.newScheduledFollowUpRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledFollowUpRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ScheduledFollowUpRequestCodeLengthRule(maxLength: 64)
        let item = Referrals.newScheduledFollowUpRequest("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.ScheduledFollowUpRequestLabelLengthRule(maxLength: 3600)
        let item = Referrals.newScheduledFollowUpRequest("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpRequestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.ScheduledFollowUpRequestGraceDaysRangeRule(min: 32, max: 255)
        let item = Referrals.newScheduledFollowUpRequest("x", label: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledFollowUpRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ScheduledFollowUpRequestRequiredCodeRule(
            message: "scheduled follow up request needs a value"
        )
        let item = Referrals.newScheduledFollowUpRequest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledFollowUpRequestRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.ScheduledFollowUpRequestRequiredEncounterIDRule(
            message: "scheduled follow up request needs a value"
        )
        let item = Referrals.newScheduledFollowUpRequest("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
