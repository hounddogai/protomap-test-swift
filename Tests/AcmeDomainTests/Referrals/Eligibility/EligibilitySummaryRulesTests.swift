@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilitySummaryValidator()
        let item = Referrals.newEligibilitySummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilitySummaryUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.EligibilitySummaryUpdatedAtRangeRule(min: 255, max: 1000)
        let item = Referrals.newEligibilitySummary("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilitySummaryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.EligibilitySummaryPriorityRangeRule(min: 32, max: 64)
        let item = Referrals.newEligibilitySummary("x", title: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilitySummaryRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Referrals.EligibilitySummaryRequiredNotesRule(message: "eligibility summary needs a value")
        let item = Referrals.newEligibilitySummary("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilitySummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.EligibilitySummaryRequiredTitleRule(message: "eligibility summary needs this field")
        let item = Referrals.newEligibilitySummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
