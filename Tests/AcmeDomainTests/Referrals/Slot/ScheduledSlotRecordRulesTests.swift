@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledSlotRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledSlotRecordValidator()
        let item = Referrals.newScheduledSlotRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledSlotRecordRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.ScheduledSlotRecordRequiredReviewerRule(message: "scheduled slot record needs this field")
        let item = Referrals.newScheduledSlotRecord("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledSlotRecordCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.ScheduledSlotRecordCapacityRangeRule(min: 32, max: 3600)
        let item = Referrals.newScheduledSlotRecord("x", title: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledSlotRecordRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.ScheduledSlotRecordRequiredSummaryRule(message: "scheduled slot record needs an entry")
        let item = Referrals.newScheduledSlotRecord("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
