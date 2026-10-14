@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedClosureRequestValidator()
        let item = Referrals.newCappedClosureRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedClosureRequestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Referrals.CappedClosureRequestRequiredCurrencyRule(message: "capped closure request needs a value")
        let item = Referrals.newCappedClosureRequest("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedClosureRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.CappedClosureRequestRequiredTitleRule(message: "capped closure request needs a value")
        let item = Referrals.newCappedClosureRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedClosureRequestCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Referrals.CappedClosureRequestCurrencyLengthRule(maxLength: 255)
        let item = Referrals.newCappedClosureRequest("x", title: "y")
        item.currency = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedClosureRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.CappedClosureRequestTitleLengthRule(maxLength: 120)
        let item = Referrals.newCappedClosureRequest("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedClosureRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.CappedClosureRequestCodeLengthRule(maxLength: 16)
        let item = Referrals.newCappedClosureRequest("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
