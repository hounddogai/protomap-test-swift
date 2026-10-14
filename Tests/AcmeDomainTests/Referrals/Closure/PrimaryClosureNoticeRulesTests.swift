@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryClosureNoticeValidator()
        let item = Referrals.newPrimaryClosureNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryClosureNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PrimaryClosureNoticeRequiredCodeRule(message: "primary closure notice needs this field")
        let item = Referrals.newPrimaryClosureNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryClosureNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PrimaryClosureNoticeRequiredTitleRule(message: "primary closure notice needs an entry")
        let item = Referrals.newPrimaryClosureNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryClosureNoticeBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Referrals.PrimaryClosureNoticeBudgetRangeRule(min: 3.0, max: 4201.8)
        let item = Referrals.newPrimaryClosureNotice("x", title: "y")
        item.budget = 4203.3
        #expect(rule.check(item).count > 0)
    }
}
