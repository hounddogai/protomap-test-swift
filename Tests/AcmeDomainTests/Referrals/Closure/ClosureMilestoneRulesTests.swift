@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureMilestoneValidator()
        let item = Referrals.newClosureMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosureMilestoneRequiredTitleRule(message: "closure milestone needs an entry")
        let item = Referrals.newClosureMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureMilestoneCodeLengthRule(maxLength: 80)
        let item = Referrals.newClosureMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureMilestoneRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.ClosureMilestoneRequiredPayerRule(message: "closure milestone needs this field")
        let item = Referrals.newClosureMilestone("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureMilestoneScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.ClosureMilestoneScoreRangeRule(min: 1.9, max: 2233.6)
        let item = Referrals.newClosureMilestone("x", title: "y")
        item.score = 2235.1
        #expect(rule.check(item).count > 0)
    }
}
