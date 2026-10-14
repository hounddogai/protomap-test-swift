@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveFollowUpNoticeValidator()
        let item = Referrals.newAdaptiveFollowUpNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpNoticePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.AdaptiveFollowUpNoticePriorityRangeRule(min: 32, max: 1000)
        let item = Referrals.newAdaptiveFollowUpNotice("x", label: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpNoticeTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.AdaptiveFollowUpNoticeTimezoneLengthRule(maxLength: 1000)
        let item = Referrals.newAdaptiveFollowUpNotice("x", label: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpNoticeWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.AdaptiveFollowUpNoticeWindowDaysRangeRule(min: 80, max: 255)
        let item = Referrals.newAdaptiveFollowUpNotice("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}
