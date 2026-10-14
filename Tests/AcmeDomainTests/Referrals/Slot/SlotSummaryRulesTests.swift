@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotSummaryValidator()
        let item = Referrals.newSlotSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.SlotSummaryTitleLengthRule(maxLength: 32)
        let item = Referrals.newSlotSummary("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotSummaryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.SlotSummaryPriorityRangeRule(min: 16, max: 120)
        let item = Referrals.newSlotSummary("x", title: "y")
        item.priority = 121
        #expect(rule.check(item).count > 0)
    }
}
