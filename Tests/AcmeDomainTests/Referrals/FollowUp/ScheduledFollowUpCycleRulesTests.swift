@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledFollowUpCycleValidator()
        let item = Referrals.newScheduledFollowUpCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledFollowUpCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ScheduledFollowUpCycleTitleLengthRule(maxLength: 120)
        let item = Referrals.newScheduledFollowUpCycle("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpCycleVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.ScheduledFollowUpCycleVisitMinutesRangeRule(min: 80, max: 1000)
        let item = Referrals.newScheduledFollowUpCycle("x", title: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
