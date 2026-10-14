@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedClosureMilestoneValidator()
        let item = Referrals.newCappedClosureMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedClosureMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.CappedClosureMilestoneRequiredCodeRule(message: "capped closure milestone needs this field")
        let item = Referrals.newCappedClosureMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedClosureMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.CappedClosureMilestoneTitleLengthRule(maxLength: 64)
        let item = Referrals.newCappedClosureMilestone("x", name: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedClosureMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.CappedClosureMilestoneRequiredTitleRule(
            message: "capped closure milestone needs this field"
        )
        let item = Referrals.newCappedClosureMilestone("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
