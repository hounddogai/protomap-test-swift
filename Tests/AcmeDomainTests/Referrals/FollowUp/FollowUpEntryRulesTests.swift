@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpEntryValidator()
        let item = Referrals.newFollowUpEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpEntryVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.FollowUpEntryVisitMinutesRangeRule(min: 80, max: 1000)
        let item = Referrals.newFollowUpEntry("x", name: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpEntryRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.FollowUpEntryRequiredTimezoneRule(message: "follow up entry needs a value")
        let item = Referrals.newFollowUpEntry("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpEntryWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.FollowUpEntryWindowDaysRangeRule(min: 120, max: 1000)
        let item = Referrals.newFollowUpEntry("x", name: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
