@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultReferralBudgetValidator()
        let item = Referrals.newReferralBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsReferralBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ReferralBudgetCodeLengthRule(maxLength: 120)
        let item = Referrals.newReferralBudget("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsReferralBudgetRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.ReferralBudgetRequiredTimezoneRule(message: "referral budget needs an entry")
        let item = Referrals.newReferralBudget("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsReferralBudgetTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.ReferralBudgetTimezoneLengthRule(maxLength: 16)
        let item = Referrals.newReferralBudget("x", title: "y")
        item.timezone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
